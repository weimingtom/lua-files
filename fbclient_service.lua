--[=[
	Firebird Service Manager API

	Based on the latest jrd/ibase.h and jrd/svc.cpp located at:
		http://firebird.cvs.sourceforge.net/viewvc/*checkout*/firebird/firebird2/src/jrd/ibase.h
		http://firebird.cvs.sourceforge.net/viewvc/*checkout*/firebird/firebird2/src/jrd/svc.cpp
	and with the help of the Interbase 6 API Guide and the latest Firebird 2.5 (RC1) release notes.

	fb.connect_service(svcname, spb) -> conn; for TCP/IP, svcname has the form "<hostname>:service_mgr"
	conn:close()
	conn:start(action, [options_t])
	conn:query(options_t, [spb], [info_buf, info_buf_len]) -> info_t, result_buffer, result_buffer_size

	USAGE/NOTES:
	- all names of constants are preserved from ibase.h so you can easily look them up in the
	Interbase 6 API guide to see what they mean.

	LIMITATIONS:
	- isc_spb_sts_hdr_pages inhibits the effect of other sts options (interbase documented behavior)
	- isc_info_svc_line and isc_info_svc_to_eof hangs if the buffer is empty even if no more info is expected.

]=]

local fbclient = require'fbclient'
local pb = require'fbclient_pb'
local struct = require'struct'
local glue = require'glue'
local asserts = glue.assert

--Attach SPB = Attach Service Parameter Block: used for attaching to the Service Manager.
local attach_spb_codes = {
	isc_spb_sys_user_name       =  19, --string: sysdba's username
	isc_spb_user_name           =  28, --string: username
	isc_spb_password            =  29, --string: password
	isc_spb_password_enc        =  30, --string: encrypted password
	isc_spb_sys_user_name_enc   =  31, --string: encrypted username
	isc_spb_process_id          = 110, --number: pid
	isc_spb_process_name        = 112, --number: process name
	isc_spb_trusted_auth        = 111, --true: force trusted authentication; fb 2.0+
	--isc_spb_command_line      = 105, --undocumented and used only by gbak to send its original command line to services manager
	isc_spb_address_path        = 109, --string: protocol dependent network address of the remote client
									   --including intermediate hosts in the case of redirection
	isc_spb_connect_timeout     =  57, --number: terminate connection if no traffic for n seconds
	isc_spb_dummy_packet_interval= 58, --number: interval between keep-alive packets
}

local attach_spb_encoders = {
	isc_spb_sys_user_name       = pb.encode_string,
	isc_spb_user_name           = pb.encode_string,
	isc_spb_password            = pb.encode_string,
	isc_spb_password_enc        = pb.encode_string,
	isc_spb_sys_user_name_enc   = pb.encode_string,
	isc_spb_process_id          = pb.encode_int,
	isc_spb_process_name        = pb.encode_string,
	isc_spb_trusted_auth        = pb.encode_zero,
	--isc_spb_command_line      = pb.encode_string,
	isc_spb_address_path        = pb.encode_string,
	isc_spb_connect_timeout     = pb.encode_int,
	isc_spb_dummy_packet_interval = pb.encode_int,
}

local function attach_spb_encode(opts)
	return pb.encode('Attach SPB', '\2\2', opts, attach_spb_codes, attach_spb_encoders)
end

--connections

local conn = {}
local conn_meta = {__index = conn}

local function attach(client_library, svcname, spb)
	--caller object
	local caller = fbclient.caller(client_library)

	--connection handle
	local svh = ffi.new'isc_svc_handle[1]'
	local spb_s = attach_spb_encode(spb)
	caller.call('isc_service_attach', #svcname, svcname, svh, spb_s and #spb_s or 0, spb_s)

	--connection object
	local cn = setmetatable({}, conn_meta)
	cn.svh = svh
	cn.caller = caller
	cn.call = caller.call
	return cn
end

local function attach_args(t, ...)
	local spb = {}
	if type(t) == 'string' then
		return t, nil, spb
	else
		glue.merge(spb, t.spb) --user's spb shouldn't overwrite explicit args
		return t.service, t.client_library, spb
	end
end

function fbclient.connect_service(...)
	return attach(attach_args(...))
end

function conn:close()
	self.call('isc_service_detach', self.svh)
end

--encode_*() functions used below for encoding individual Request Buffer action options in encoding tables.

--same as pb.encode_string but encodes #s as short, not byte
local function encode_string(v)
	asserts(#v <= MAX_USHORT, 'strint too long, max. is %d bytes', MAX_USHORT)
	return struct.pack('<Hc0',#v,v)
end

--bitmasks encode to a uint without length marker
local function encode_bitmask(bits)
	return function(t)
		local n = 0
		for k,v in pairs(t) do
			local bit = asserts(bits[k], 'invalid bitmask option %s',k)
			assert(v==true,'an option that takes no arguments must be given the value true')
			--adding the bitmasks does not carry so it's equivalent to binary and in this case
			n = n + bit
		end
		assert(isuint(n))
		return struct.pack('<I',n)
	end
end

--encode_none is the same as for TPBs
local function encode_none(v)
	assert(v==true,'an option that takes no arguments must be given the value true')
	return ''
end

--same as pb.encode_enum(), but without length marker
local function encode_enum(t)
	return function(v)
		local tv = t[v]
		asserts(tv,'invalid enum constant %s',tv)
		assert(isbyte(tv))
		return struct.pack('B',tv)
	end
end

--same as pb.encode_uint(), but without length marker
local function encode_uint(v)
	asserts(v and isuint(v),'32bit unsigned integer expected')
	return struct.pack('<I',v)
end

--t is either a string or an array of the form {filename1,filesize1,filename2,filesize2,...,filenameN}
local function encode_backup_file_list(t)
	local isc_spb_bkp_file = 5
	local isc_spb_bkp_length = 7
	if applicable(t,'__ipairs') then
		local s = ''
		for i,v in ipairs(t) do
			if i==1 then --the first filename already has isc_spb_bkp_file in the option buffer!
				s = s..encode_string(v)
			elseif i%2==1 then
				s = s..struct.pack('B',isc_spb_bkp_file)..encode_string(v)
			else
				s = s..struct.pack('B',isc_spb_bkp_length)..encode_uint(v)
			end
		end
		return s
	else --in case you just want to provide a single backup file, there's no need to put it in a table.
		return encode_string(t)
	end
end

local function encode_array(opt_code,element_encoder)
	return function(t)
		if applicable(t,'__ipairs') then
			local s = ''
			for i,v in ipairs(t) do
				if i==1 then --the first element already has opt_code in the output buffer!
					s = s..element_encoder(v)
				else
					s = s..struct.pack('B',opt_code)..element_encoder(v)
				end
			end
			return s
		else
			--in case you just want to provide a single element, there's no need to put it in a table.
			--this means that array elements cannot be ipair'able themselves!
			return element_encoder(t)
		end
	end
end

--actions: they represent tasks to be started over a Service Manager connection.
local action_codes = {
	--full backup/restore (gbak)
	isc_action_svc_backup			= 1,	--Starts database backup process on the server
	isc_action_svc_restore			= 2,	--Starts database restore process on the server
	--repair databases
	isc_action_svc_repair			= 3,	--Starts database repair process on the server
	--user management
	isc_action_svc_add_user			= 4,	--Adds a new user to the security database
	isc_action_svc_delete_user		= 5,	--Deletes a user record from the security database
	isc_action_svc_modify_user		= 6,	--Modifies a user record in the security database
	isc_action_svc_display_user		= 7,	--Displays a user record from the security database
	--set db properties
	isc_action_svc_properties		= 8,	--Sets database properties
	--license management (useless)
	isc_action_svc_add_license		= 9,	--Adds a license to the license file
	isc_action_svc_remove_license	= 10,	--Removes a license from the license file
	--get db statistics
	isc_action_svc_db_stats			= 11,	--Retrieves database statistics
	--get log file content
	isc_action_svc_get_ib_log		= 12,	--Retrieves the InterBase log file from the server
	isc_action_svc_get_fb_log		= 12,	--Retrieves the Firebird log file from the server (same code!)
	--trace services (firebird 2.5+)
	isc_action_svc_trace_start		= 22,	--Start trace session
	isc_action_svc_trace_stop		= 23,	--Stop trace session
	isc_action_svc_trace_suspend	= 24,	--Suspend trace session
	isc_action_svc_trace_resume		= 25,	--Resume trace session
	isc_action_svc_trace_list		= 26,	--List existing sessions
	--RDB$ADMIN mapping (firebird 2.5+)
	isc_action_svc_set_mapping		= 27,	--Set auto admins mapping in security database
	isc_action_svc_drop_mapping		= 28,	--Drop auto admins mapping in security database
	--incremental backup/restore (nbackup)
	isc_action_svc_nbak				= 20,	--Incremental nbackup
	isc_action_svc_nrest			= 21,	--Incremental database restore
}

--common enums
local isc_spb_prp_reserve_space_enum = {
	isc_spb_prp_res_use_full	= 35,
	isc_spb_prp_res				= 36,
}

local isc_spb_prp_write_mode_enum = {
	isc_spb_prp_wm_async		= 37,
	isc_spb_prp_wm_sync			= 38,
}

--backup action
local isc_action_svc_backup_codes = {
	isc_spb_dbname		= 106, --string
	isc_spb_verbose		= 107, --boolean
	isc_spb_options		= 108, --bitmask isc_action_svc_backup_bits
	isc_spb_bkp_file	=   5, --either filename or {filename1,length1,filename2,length2,...,filenameN}
	isc_spb_bkp_factor	=   6, --blocking size for tape drives, whatever that means
}

local isc_action_svc_backup_option_order = {
	'isc_spb_dbname',
	'isc_spb_verbose',
	'isc_spb_options',
	'isc_spb_bkp_file',
	'isc_spb_bkp_factor',
}

local isc_action_svc_backup_bits = {
	isc_spb_bkp_ignore_checksums	= 0x01,
	isc_spb_bkp_ignore_limbo		= 0x02,
	isc_spb_bkp_metadata_only		= 0x04,
	isc_spb_bkp_no_garbage_collect	= 0x08,
	isc_spb_bkp_old_descriptions	= 0x10,
	isc_spb_bkp_non_transportable	= 0x20,
	isc_spb_bkp_convert				= 0x40,
	isc_spb_bkp_expand				= 0x80,	--undocumented and unimplemented in Firebird
	isc_spb_bkp_no_triggers		  = 0x8000, --disable triggers from firing during backup; firebird 2.1+
}

local isc_action_svc_backup_encoders = {
	isc_spb_dbname		= encode_string,
	isc_spb_verbose		= encode_none,
	isc_spb_bkp_file	= encode_backup_file_list,
	isc_spb_bkp_factor	= encode_uint,
	isc_spb_options		= encode_bitmask(isc_action_svc_backup_bits),
}

--restore action
local isc_action_svc_restore_codes = {
	isc_spb_bkp_file		=   5,
	isc_spb_dbname			= 106,
	isc_spb_res_length		=  11,	--what's this for???
	isc_spb_verbose			= 107,
	isc_spb_res_buffers		=   9,
	isc_spb_res_page_size	=  10,
	isc_spb_res_access_mode	=  12,
	isc_spb_options			= 108,
	isc_spb_res_fix_fss_data		= 13, --firebird 2.5+
	isc_spb_res_fix_fss_metadata	= 14, --firebird 2.5+
}

local isc_action_svc_restore_bits = {
	isc_spb_res_deactivate_idx	= 0x0100,
	isc_spb_res_no_shadow		= 0x0200,
	isc_spb_res_no_validity		= 0x0400,
	isc_spb_res_one_at_a_time	= 0x0800,
	isc_spb_res_replace			= 0x1000,
	isc_spb_res_create			= 0x2000,
	isc_spb_res_use_all_space	= 0x4000,
}

local isc_spb_res_access_mode_enum = {
	isc_spb_res_am_readonly		= 39,
	isc_spb_res_am_readwrite	= 40,
}

local isc_action_svc_restore_encoders = {
	isc_spb_bkp_file		= encode_array(isc_action_svc_restore_codes.isc_spb_bkp_file, encode_string),
	isc_spb_dbname			= encode_string,
	isc_spb_res_length		= encode_uint,
	isc_spb_verbose			= encode_none,
	isc_spb_res_buffers		= encode_uint,
	isc_spb_res_page_size	= encode_uint, --type not documented!
	isc_spb_res_access_mode	= encode_enum(isc_spb_res_access_mode_enum),
	isc_spb_options			= encode_bitmask(isc_action_svc_restore_bits),
	isc_spb_res_fix_fss_data     = encode_none,
	isc_spb_res_fix_fss_metadata = encode_none,
}

--setting database properties action
local isc_action_svc_properties_codes = {
	isc_spb_dbname						= 106,
	isc_spb_options						= 108,
	isc_spb_prp_page_buffers			=   5,
	isc_spb_prp_sweep_interval			=   6,
	isc_spb_prp_shutdown_db				=   7,
	isc_spb_prp_deny_new_attachments	=   9,
	isc_spb_prp_deny_new_transactions	=  10,
	isc_spb_prp_reserve_space			=  11,
	isc_spb_prp_write_mode				=  12,
	isc_spb_prp_access_mode				=  13,
	isc_spb_prp_set_sql_dialect			=  14,
	isc_spb_prp_shutdown_mode			=  44,
	isc_spb_prp_online_mode				=  45,
}

local isc_action_svc_properties_bits = {
	isc_spb_prp_activate	= 0x0100,
	isc_spb_prp_db_online	= 0x0200,
}

local isc_spb_prp_shutdown_mode_enum = {
	isc_spb_prp_sm_normal = 0, --return to normal state, default for isc_spb_prp_online_mode
	isc_spb_prp_sm_multi  = 1, --multi-user maintenance mode, default for isc_spb_prp_shutdown_mode
	isc_spb_prp_sm_single = 2, --shutdown to single-user maintenance mode
	isc_spb_prp_sm_full   = 3, --full shutdown, disabling new connections
}

local isc_spb_prp_access_mode_enum = {
	isc_spb_prp_am_readonly		= 39,
	isc_spb_prp_am_readwrite	= 40,
}

local isc_action_svc_properties_encoders = {
	isc_spb_dbname						= encode_string,
	isc_spb_prp_page_buffers			= encode_uint,
	isc_spb_prp_sweep_interval			= encode_uint,
	isc_spb_prp_shutdown_db				= encode_uint,
	isc_spb_prp_deny_new_attachments	= encode_uint,
	isc_spb_prp_deny_new_transactions	= encode_uint,
	isc_spb_prp_reserve_space			= encode_enum(isc_spb_prp_reserve_space_enum),
	isc_spb_prp_write_mode				= encode_enum(isc_spb_prp_write_mode_enum),
	isc_spb_prp_access_mode				= encode_enum(isc_spb_prp_access_mode_enum),
	isc_spb_prp_set_sql_dialect			= encode_uint, --1 or 3
	isc_spb_options						= encode_bitmask(isc_action_svc_properties_bits),
	isc_spb_prp_shutdown_mode			= encode_enum(isc_spb_prp_shutdown_mode_enum),
	isc_spb_prp_online_mode				= encode_enum(isc_spb_prp_shutdown_mode_enum),
}

--repair action
local isc_action_svc_repair_codes = {
	isc_spb_dbname					= 106,
	isc_spb_options					= 108,
	--repair limbo transactions
	isc_spb_rpr_commit_trans		=  15,
	isc_spb_rpr_rollback_trans		=  34,
	isc_spb_rpr_recover_two_phase	=  17,
	isc_spb_tra_id					=  18,
}

local isc_action_svc_repair_bits = {
	isc_spb_rpr_validate_db			= 0x01,
	isc_spb_rpr_sweep_db			= 0x02,
	isc_spb_rpr_mend_db				= 0x04,
	isc_spb_rpr_list_limbo_trans	= 0x08, --mentioned in fb 2.1 relnotes ????
	isc_spb_rpr_check_db			= 0x10,
	isc_spb_rpr_ignore_checksum		= 0x20,
	isc_spb_rpr_kill_shadows		= 0x40,
	isc_spb_rpr_full				= 0x80,
}

local isc_action_svc_repair_encoders = {
	isc_spb_dbname					= encode_string,
	isc_spb_options					= encode_bitmask(isc_action_svc_repair_bits),
	isc_spb_rpr_commit_trans		= encode_none,
	isc_spb_rpr_rollback_trans		= encode_none,
	isc_spb_rpr_recover_two_phase	= encode_none,
	isc_spb_tra_id					= encode_uint,
}

--add user action
local isc_action_svc_add_user_codes = {
    isc_spb_sec_username	=   7,
	isc_spb_sec_password	=   8,
	isc_spb_sec_firstname	=  10,
	isc_spb_sec_middlename	=  11,
	isc_spb_sec_lastname	=  12,
	isc_spb_sec_userid		=   5, --reserved
	isc_spb_sec_groupid		=   6, --reserved
	isc_spb_sec_groupname	=   9, --reserved
	isc_spb_sql_role_name	=  60, --reserved
	isc_spb_dbname			= 106, --security database name (firebird 2.1+)
}

local isc_action_svc_add_user_option_order = {
	'isc_spb_sec_username',
	'isc_spb_sec_password',
	'isc_spb_sec_firstname',
	'isc_spb_sec_middlename',
	'isc_spb_sec_lastname',
	'isc_spb_sec_userid',
	'isc_spb_sec_groupid',
	'isc_spb_sec_groupname',
	'isc_spb_sql_role_name',
	'isc_spb_dbname',
}

local isc_action_svc_modify_user_option_order = isc_action_svc_add_user_option_order

local isc_action_svc_add_user_encoders = {
	isc_spb_sec_username    = encode_string,
	isc_spb_sec_password    = encode_string,
	isc_spb_sec_firstname   = encode_string,
	isc_spb_sec_middlename  = encode_string,
	isc_spb_sec_lastname    = encode_string,
	isc_spb_sec_userid      = encode_uint,
	isc_spb_sec_groupid     = encode_uint,
	isc_spb_sec_groupname   = encode_string,
	isc_spb_sql_role_name   = encode_string,
	isc_spb_dbname			= encode_string,
}

--modify user action; same as adding; modifying goes by username, which you cannot change.
local isc_action_svc_modify_user_codes = isc_action_svc_add_user_codes
local isc_action_svc_modify_user_encoders = isc_action_svc_add_user_encoders

--del user action
local isc_action_svc_delete_user_codes = {
	isc_spb_sec_username  =   7,
	isc_spb_sql_role_name =  60, --reserved
	isc_spb_dbname        = 106, --security database name (firebird 2.1+)
}

local isc_action_svc_delete_user_encoders = {
	isc_spb_sec_username  = encode_string,
	isc_spb_sql_role_name = encode_string,
	isc_spb_dbname        = encode_string,
}

local isc_action_svc_delete_user_option_order = {
	'isc_spb_sec_username',
	'isc_spb_sql_role_name',
	'isc_spb_dbname',
}

--display user action; ommit username to display all users
local isc_action_svc_display_user_codes = {
	isc_spb_sec_username = 7,
	isc_spb_dbname       = 106, --security database name (firebird 2.1+)
}

local isc_action_svc_display_user_encoders = {
	isc_spb_sec_username = encode_string,
	isc_spb_dbname       = encode_string,
}

local isc_action_svc_display_user_option_order = {
	'isc_spb_sec_username',
	'isc_spb_dbname',
}

--add license action
local isc_action_svc_add_license_codes = {
	isc_spb_lic_key	= 5,
	isc_spb_lic_id	= 6,
}

local isc_action_svc_add_license_codes = {
	isc_spb_lic_key = encode_string,
	isc_spb_lic_id  = encode_string,
}

--del license action; same as adding
local isc_action_svc_del_license_codes = isc_action_svc_add_license_codes
local isc_action_svc_del_license_encoders = isc_action_svc_add_license_encoders

--get db statistics action
local isc_action_svc_db_stats_codes = {
	isc_spb_dbname  = 106,
	isc_spb_options = 108,
}

local isc_info_svc_db_stats_bits = {
	isc_spb_sts_data_pages      = 0x01,
	isc_spb_sts_db_log          = 0x02, --WAL is unavailable in firebird
	isc_spb_sts_hdr_pages       = 0x04,
	isc_spb_sts_idx_pages       = 0x08,
	isc_spb_sts_sys_relations   = 0x10,
	isc_spb_sts_record_versions = 0x20, --analyze average record and version length
	isc_spb_sts_table           = 0x40, --undocumented; must be a list of table names, but it's a bitmask instead (?!)
	isc_spb_sts_nocreation      = 0x80, --special switch to avoid including creation date, only for tests (no message)
}

local isc_action_svc_db_stats_encoders = {
	isc_spb_dbname  = encode_string,
	isc_spb_options = encode_bitmask(isc_info_svc_db_stats_bits),
}

--get interbase log file action
local isc_action_svc_get_ib_log_codes = {}
local isc_action_svc_get_ib_log_encoders = {}

--get firebird log file action (same code, same empty table of codes and encoders)
local isc_action_svc_get_fb_log_codes = isc_action_svc_get_ib_log_codes
local isc_action_svc_get_fb_log_encoders = isc_action_svc_get_ib_log_encoders

--trace_start action
local isc_action_svc_trace_start_codes = {
	isc_spb_trc_name = 2, --trace session name, string, optional
	isc_spb_trc_cfg  = 3, --trace session configuration, string, mandatory
}

local isc_action_svc_trace_start_encoders = {
	isc_spb_trc_name = encode_string,
	isc_spb_trc_cfg  = encode_string,
}

--trace_stop action
local isc_action_svc_trace_stop_codes = {
	isc_spb_trc_id = 1, --trace session ID, integer, mandatory
}

local isc_action_svc_trace_stop_encoders = {
	isc_spb_trc_id = encode_uint,
}

--trace_suspend action
local isc_action_svc_trace_suspend_codes = isc_action_svc_trace_stop_codes
local isc_action_svc_trace_suspend_encoders = isc_action_svc_trace_stop_encoders

--trace_resume action
local isc_action_svc_trace_resume_codes = isc_action_svc_trace_stop_codes
local isc_action_svc_trace_resume_encoders = isc_action_svc_trace_stop_encoders

--trace_list action
local isc_action_svc_trace_list_codes = {}
local isc_action_svc_trace_list_encoders = {}

--RDB$ADMIN mapping action
local isc_action_svc_set_mapping_codes = {}
local isc_action_svc_set_mapping_encoders = {}
local isc_action_svc_drop_mapping_codes = {}
local isc_action_svc_drop_mapping_encoders = {}

--nbackup backup action
local isc_action_svc_nbak_codes = {
	isc_spb_dbname			= 106, --string
	isc_spb_options			= 108, --bitmask isc_action_svc_nbak_bits
	isc_spb_nbk_level		=   5, --backup level (integer)
	isc_spb_nbk_file		=   6, --backup file name (string)
}

local isc_action_svc_nbak_bits = {
	isc_spb_nbk_no_triggers = 0x01, --suppress database triggers
}

local isc_action_svc_nbak_encoders = {
	isc_spb_dbname		= encode_string,
	isc_spb_options		= encode_bitmask(isc_action_svc_nbak_bits),
	isc_spb_nbk_level	= encode_uint,
	isc_spb_nbk_file	= encode_string,
}

--nbackup restore action
local isc_action_svc_nrest_codes = {
	isc_spb_dbname			= 106, --string
	isc_spb_options			= 108, --bitmask isc_action_svc_nrest_bits
	isc_spb_nbk_file		=   6, --backup file name (string)
}

local isc_action_svc_nrest_bits = {
	isc_spb_nbk_no_triggers = 0x01, --suppress database triggers
}

local isc_action_svc_nrest_encoders = {
	isc_spb_dbname		= encode_string,
	isc_spb_options		= encode_bitmask(isc_action_svc_nrest_bits),
	isc_spb_nbk_file	= encode_array(isc_action_svc_nrest_codes.isc_spb_nbk_file, encode_string),
}

--table of actions and corresponding option code tables
local action_options_codes = {
	isc_action_svc_backup			= isc_action_svc_backup_codes,
	isc_action_svc_restore			= isc_action_svc_restore_codes,
	isc_action_svc_repair			= isc_action_svc_repair_codes,
	isc_action_svc_add_user			= isc_action_svc_add_user_codes,
	isc_action_svc_delete_user		= isc_action_svc_delete_user_codes,
	isc_action_svc_modify_user		= isc_action_svc_modify_user_codes,
	isc_action_svc_display_user		= isc_action_svc_display_user_codes,
	isc_action_svc_properties		= isc_action_svc_properties_codes,
	isc_action_svc_add_license		= isc_action_svc_add_license_codes,
	isc_action_svc_remove_license	= isc_action_svc_remove_license_codes,
	isc_action_svc_db_stats			= isc_action_svc_db_stats_codes,
	isc_action_svc_get_ib_log		= isc_action_svc_get_ib_log_codes,
	isc_action_svc_get_fb_log		= isc_action_svc_get_fb_log_codes,
	isc_action_svc_trace_start		= isc_action_svc_trace_start_codes,
	isc_action_svc_trace_stop		= isc_action_svc_trace_stop_codes,
	isc_action_svc_trace_suspend	= isc_action_svc_trace_suspend_codes,
	isc_action_svc_trace_resume		= isc_action_svc_trace_resume_codes,
	isc_action_svc_trace_list		= isc_action_svc_trace_list_codes,
	isc_action_svc_set_mapping		= isc_action_svc_set_mapping_codes,
	isc_action_svc_drop_mapping		= isc_action_svc_drop_mapping_codes,
	isc_action_svc_nbak				= isc_action_svc_nbak_codes,
	isc_action_svc_nrest			= isc_action_svc_nrest_codes,
}

--table of actions and corresponding option encoder tables
local action_options_encoders = {
	isc_action_svc_backup			= isc_action_svc_backup_encoders,
	isc_action_svc_restore			= isc_action_svc_restore_encoders,
	isc_action_svc_repair			= isc_action_svc_repair_encoders,
	isc_action_svc_add_user			= isc_action_svc_add_user_encoders,
	isc_action_svc_delete_user		= isc_action_svc_delete_user_encoders,
	isc_action_svc_modify_user		= isc_action_svc_modify_user_encoders,
	isc_action_svc_display_user		= isc_action_svc_display_user_encoders,
	isc_action_svc_properties		= isc_action_svc_properties_encoders,
	isc_action_svc_add_license		= isc_action_svc_add_license_encoders,
	isc_action_svc_remove_license	= isc_action_svc_remove_license_encoders,
	isc_action_svc_db_stats			= isc_action_svc_db_stats_encoders,
	isc_action_svc_get_ib_log		= isc_action_svc_get_ib_log_encoders,
	isc_action_svc_get_fb_log		= isc_action_svc_get_fb_log_encoders,
	isc_action_svc_trace_start		= isc_action_svc_trace_start_encoders,
	isc_action_svc_trace_stop		= isc_action_svc_trace_stop_encoders,
	isc_action_svc_trace_suspend	= isc_action_svc_trace_suspend_encoders,
	isc_action_svc_trace_resume		= isc_action_svc_trace_resume_encoders,
	isc_action_svc_trace_list		= isc_action_svc_trace_list_encoders,
	isc_action_svc_set_mapping		= isc_action_svc_set_mapping_encoders,
	isc_action_svc_drop_mapping		= isc_action_svc_drop_mapping_encoders,
	isc_action_svc_nbak				= isc_action_svc_nbak_encoders,
	isc_action_svc_nrest			= isc_action_svc_nrest_encoders,
}

--table of actions and corresponding option order tables (some actions expect their options in a specific order!!)
local action_options_order_tables = {
	isc_action_svc_add_user     = isc_action_svc_add_user_option_order,
	isc_action_svc_modify_user  = isc_action_svc_modify_user_option_order,
	isc_action_svc_delete_user  = isc_action_svc_delete_user_option_order,
	isc_action_svc_display_user = isc_action_svc_display_user_option_order,
	isc_action_svc_backup       = isc_action_svc_backup_option_order,
}

function conn:start(action, opts)
	--encode a RB (Request Buffer) from action and opts.
	local action_code = asserts(action_codes[action],'invalid action %s', action)
	local opt_codes = asserts(action_options_codes[action],'invalid action %s', action)
	local opt_encoders = asserts(action_options_encoders[action],'option encoders table missing for action %s', action)

	opts = opts or {}

	--if no order is imposed, make opt_list out of opts keys.
	--keys() always return an ipair()'able array since tables can't have nil keys
	local opt_list = action_options_order_tables[action] or keys(opts)

	local s = struct.pack('B', action_code)

	for i,opt in ipairs(opt_list) do
		local opt_val = opts[opt]
		if opt_val ~= nil then
			asserts(opt_codes[opt], 'invalid option %s for action %s', opt, action)
			asserts(opt_encoders[opt], 'encoder missing for option %s of action %s', opt, action)
			s = s..struct.pack('B', opt_codes[opt]) .. opt_encoders[opt](opt_val)
		end
	end
	self.call('isc_service_start', svh, nil, #s, s)
end

--Query SPB: used for parametrizing a query to an Service Manager connections.

local query_spb_codes = {
	isc_info_svc_timeout = 64,	--Sets a timeout value in seconds for waiting on service information
}

local query_spb_encoders = {
	isc_info_svc_timeout = encode_uint,
}

local function query_spb_encode(opts)
	return pb.encode('Query SPB', '\2\2', opts, attach_spb_codes, attach_spb_encoders)
end

--info codes, buffer sizes, and encoders: used for encoding and decoding info requests and replies
--on the Service Manager.

local info_codes = {
	isc_info_svc_svr_db_info		= 50,	--get number of connections and databases
	isc_info_svc_get_license		= 51,	--get all license keys and IDs from the license file
	isc_info_svc_get_license_mask	= 52,	--get bitmask representing licensed options on the server
	isc_info_svc_get_config			= 53,	--get parameters and values for IB_CONFIG
	isc_info_svc_version			= 54,	--get version of the services manager
	isc_info_svc_server_version		= 55,	--get version of the Firebird server
	isc_info_svc_implementation		= 56,	--get implementation of the Firebird server
	isc_info_svc_capabilities		= 57,	--get bitmask representing the server's capabilities
	isc_info_svc_user_dbpath		= 58,	--get path to the security database in use by the server
	isc_info_svc_get_env			= 59,	--get setting of $FIREBIRD
	isc_info_svc_get_env_lock		= 60,	--get setting of $FIREBIRD_LCK
	isc_info_svc_get_env_msg		= 61,	--get setting of $FIREBIRD_MSG
	isc_info_svc_line				= 62,	--get 1 line of service output per call; '' means no more output
	isc_info_svc_to_eof				= 63,	--get as much of the server output as will fit in the supplied buffer
	isc_info_svc_get_licensed_users	= 65,	--get number of users licensed for accessing the server
	isc_info_svc_limbo_trans		= 66,	--get limbo transactions
	isc_info_svc_running			= 67,	--get check to see if a service is running on a connection
	isc_info_svc_get_users			= 68,	--get user information from isc_action_svc_display_users
}

local info_code_lookup = index(info_codes)

local info_buf_sizes = {
	isc_info_svc_svr_db_info		= MAX_USHORT,
	isc_info_svc_get_license		= MAX_USHORT,
	isc_info_svc_get_license_mask	= INT_SIZE,
	isc_info_svc_get_config			= SHORT_SIZE+(1+INT_SIZE)*100, --reserve space for 100 config items
	isc_info_svc_version			= INT_SIZE,
	isc_info_svc_server_version		= SHORT_SIZE+255,
	isc_info_svc_implementation		= SHORT_SIZE+255,
	isc_info_svc_capabilities		= INT_SIZE,
	isc_info_svc_user_dbpath		= SHORT_SIZE+2048,
	isc_info_svc_get_env			= SHORT_SIZE+2048,
	isc_info_svc_get_env_lock		= SHORT_SIZE+2048,
	isc_info_svc_get_env_msg		= SHORT_SIZE+2048,
	isc_info_svc_line				= SHORT_SIZE+2048,
	isc_info_svc_to_eof				= MAX_USHORT,
	isc_info_svc_get_licensed_users	= INT_SIZE,
	isc_info_svc_limbo_trans		= MAX_USHORT,
	isc_info_svc_running			= INT_SIZE,
	isc_info_svc_get_users			= MAX_USHORT,
}

local info_end_codes = {
	isc_info_end             = 1,  --normal ending
	isc_info_truncated       = 2,  --receiving buffer too small
	isc_info_error           = 3,  --error, check status vector
	isc_info_data_not_ready  = 4,  --data not available for some reason
	isc_info_svc_timeout     = 64, --timeout expired
}

local info_end_code_lookup = index(info_end_codes)

--decoders used in the info buffer filled by query()

local function decode_uint(buf,size,ofs)
	return struct.unpack('<I',buf,size,ofs)
end

local function decode_uint_bool(buf,size,ofs)
	local i,ofs = struct.unpack('<I',buf,size,ofs)
	return i~=0,ofs
end

local function decode_string(buf,size,ofs)
	return struct.unpack('<Hc0',buf,size,ofs)
end

function decode_enum(option, enum_table)
	local enum_table_index = index(enum_table) --no synonyms for enum names allowed!
	return function(buf,size,ofs)
		local c,ofs = struct.unpack('B',buf,size,ofs)
		return asserts(enum_table_index[c],'invalid code %d returned by server for option %s',c,option),ofs
	end
end

--only used by isc_info_svc_svr_db_info and presumably by isc_info_svc_get_license
local function decode_cluster(option, codes, decoders)
	local isc_info_flag_end = 127
	local code_index = index(codes)
	return function(buf,size,ofs)
		local t = {}
		local code
		while true do
			assert(ofs <= size, 'unexpected end of info buffer')
			code,ofs = struct.unpack('B',buf,size,ofs)
			if code == isc_info_flag_end then
				break
			end
			local code_name = asserts(code_index[code],'invalid code %d returned by server for option %s',code,option)
			local decoder = asserts(decoders[code_name],'missing decoder for code %s.%s',option,code_name)
			local a = t[code_name] or {}
			a[#a+1],ofs = decoder(buf,size,ofs)
			t[code_name] = a
		end
		return t,ofs
	end
end

--only used by isc_info_svc_get_users and isc_info_svc_limbo_trans
--the difference to decode_cluster() is that you get the data length at the
--beginning instead of, or in addition to terminating isc_info_flag_end code
local function decode_sized_cluster(option, codes, decoders)
	local code_index = index(codes)
	local isc_info_flag_end = 127
	return function(buf,size,ofs)
		local t = {}
		local code
		local initial_ofs = ofs
		local actual_size,ofs = struct.unpack('<H',buf,size,ofs)
		while ofs-initial_ofs <= actual_size do
			code,ofs = struct.unpack('B',buf,size,ofs)
			if code == isc_info_flag_end then
				break
			end
			local code_name = asserts(code_index[code],'invalid code %d returned by server for option %s',code,option)
			local decoder = asserts(decoders[code_name],'missing decoder for code %s.%s',option,code_name)
			local a = t[code_name] or {}
			a[#a+1],ofs = decoder(buf,size,ofs)
			t[code_name] = a
		end
		return t,ofs
	end
end

local function decode_bitmask(bits)
	local bits_index = index(bits)
	return function(buf,size,ofs)
		local n,ofs = struct.unpack('<I',buf,size,ofs)
		local t = {}
		for mask,name in pairs(bits_index) do
			t[name] = n % (mask*2) - n % mask ~= 0 --slightly ugly trick in absence of binary operators
		end
		return t,ofs
	end
end

--db info cluster codes & decoders
local db_info_codes = {
	isc_spb_num_att	= 5,
	isc_spb_num_db	= 6,
	isc_spb_dbname	= 106,
}

local db_info_decoders = {
	isc_spb_num_att	= decode_uint,
	isc_spb_num_db	= decode_uint,
	isc_spb_dbname	= decode_string,
}

--get license cluster codes & decoders (not tested as firebird doesn't return this info code at all)
local get_license_codes = {
	isc_spb_lic_key	= 5,
	isc_spb_lic_id	= 6,
}

local get_license_decoders = {
	isc_spb_lic_key	= decode_string,
	isc_spb_lic_id	= decode_string,
}

--limbo trans cluster codes & decoders
local limbo_trans_codes = {
	isc_spb_single_tra_id		= 19,
	isc_spb_multi_tra_id		= 20,
	isc_spb_tra_state			= 21,
	isc_spb_tra_host_site		= 26,
	isc_spb_tra_remote_site		= 27,
	isc_spb_tra_db_path			= 28,
	isc_spb_tra_advise			= 29,
}

local isc_spb_tra_advise_enum = {
	isc_spb_tra_advise_commit	= 30,
	isc_spb_tra_advise_rollback	= 31,
	isc_spb_tra_advise_unknown	= 33,
}

local isc_spb_tra_state_enum = {
	isc_spb_tra_state_limbo		= 22,
	isc_spb_tra_state_commit	= 23,
	isc_spb_tra_state_rollback	= 24,
	isc_spb_tra_state_unknown	= 25,
}

local limbo_trans_decoders = {
	isc_spb_single_tra_id		= decode_uint,
	isc_spb_multi_tra_id		= decode_uint,
	isc_spb_tra_state			= decode_enum('isc_spb_tra_state', isc_spb_tra_state_enum),
	isc_spb_tra_host_site		= decode_string,
	isc_spb_tra_remote_site		= decode_string,
	isc_spb_tra_db_path			= decode_string,
	isc_spb_tra_advise			= decode_enum('isc_spb_tra_advise', isc_spb_tra_advise_enum),
}

--get config cluster is a little special
local isc_info_svc_get_config_codes = {
	ISCCFG_LOCKMEM_KEY = 0,
	ISCCFG_LOCKSEM_KEY = 1,
	ISCCFG_LOCKSIG_KEY = 2,
	ISCCFG_EVNTMEM_KEY = 3,
	ISCCFG_DBCACHE_KEY = 4,
	ISCCFG_PRIORITY_KEY = 5,
	ISCCFG_IPCMAP_KEY = 6,
	ISCCFG_MEMMIN_KEY = 7,
	ISCCFG_MEMMAX_KEY = 8,
	ISCCFG_LOCKORDER_KEY = 9,
	ISCCFG_ANYLOCKMEM_KEY = 10,
	ISCCFG_ANYLOCKSEM_KEY = 11,
	ISCCFG_ANYLOCKSIG_KEY = 12,
	ISCCFG_ANYEVNTMEM_KEY = 13,
	ISCCFG_LOCKHASH_KEY = 14,
	ISCCFG_DEADLOCK_KEY = 15,
	ISCCFG_LOCKSPIN_KEY = 16,
	ISCCFG_CONN_TIMEOUT_KEY = 17,
	ISCCFG_DUMMY_INTRVL_KEY = 18,
}

local isc_info_svc_get_config_code_lookup = index(isc_info_svc_get_config_codes)

--not tested --firebird doesn't return this info code at all
local function decode_get_config(buf,size,ofs)
	local n,ofs = struct.unpack('<H',buf,size,ofs)
	local t,ccode,cval,cname = {}
	for i=1,n do
		ccode,cval,ofs = struct.unpack('<BI',buf,size,ofs)
		cname = isc_info_svc_get_config_code_lookup[ccode]
		asserts(cname,'invalid config code %d for isc_info_svc_get_config',ccode)
		t[cname] = cval
	end
	return t,ofs
end

--cababilities bits stolen from jrd/svc.h
local isc_info_svc_capabilities_mask = {
	MULTI_CLIENT_SUPPORT			= 0x002,	--SuperServer model (vs. multi-inet)
	REMOTE_HOP_SUPPORT				= 0x004,	--Server can connect to other server
	NO_SERVER_SHUTDOWN_SUPPORT		= 0x100,	--Can not shutdown server
	SERVER_CONFIG_SUPPORT			= 0x200,	--Can configure server
	QUOTED_FILENAME_SUPPORT			= 0x400,	--Can pass quoted filenames in
}

--get users cluster codes & decoders
local get_users_codes = {
	isc_spb_sec_username	= 7,
	isc_spb_sec_firstname	= 10,
	isc_spb_sec_middlename	= 11,
	isc_spb_sec_lastname	= 12,
	isc_spb_sec_admin		= 13,
	isc_spb_sec_userid		= 5,
	isc_spb_sec_groupid		= 6,
}

local get_users_decoders = {
	isc_spb_sec_username	= decode_string,
	isc_spb_sec_firstname	= decode_string,
	isc_spb_sec_middlename	= decode_string,
	isc_spb_sec_lastname	= decode_string,
	isc_spb_sec_admin		= decode_uint_bool, --true = GRANT ADMIN ROLE, false = REVOKE ADMIN ROLE
	isc_spb_sec_userid		= decode_uint,
	isc_spb_sec_groupid		= decode_uint,
}

local info_decoders = {
	isc_info_svc_svr_db_info		= decode_cluster('isc_info_svc_svr_db_info', db_info_codes, db_info_decoders),
	isc_info_svc_get_license		= decode_cluster('isc_info_svc_get_license', get_license_codes, get_license_decoders),
	isc_info_svc_get_license_mask	= decode_uint,
	isc_info_svc_get_config			= decode_get_config,
	isc_info_svc_version			= decode_uint,
	isc_info_svc_server_version		= decode_string,
	isc_info_svc_implementation		= decode_string,
	isc_info_svc_capabilities		= decode_bitmask(isc_info_svc_capabilities_mask),
	isc_info_svc_user_dbpath		= decode_string,
	isc_info_svc_get_env			= decode_string,
	isc_info_svc_get_env_lock		= decode_string,
	isc_info_svc_get_env_msg		= decode_string,
	isc_info_svc_line				= decode_string,
	isc_info_svc_to_eof				= decode_string,
	isc_info_svc_get_licensed_users	= decode_uint,
	isc_info_svc_limbo_trans		= decode_sized_cluster('isc_info_svc_limbo_trans', limbo_trans_codes, limbo_trans_decoders),
	isc_info_svc_running			= decode_uint_bool,
	isc_info_svc_get_users			= decode_sized_cluster('isc_info_svc_get_users', get_users_codes, get_users_decoders),
}

local function info_request_encode(opts)
	local s,len = '',1 --make room for end code
	for k,v in pairs(opts) do
		local info_code = asserts(info_codes[k],'invalid option %s',k)
		--none of these options take any arguments, so <true> is the only possible parameter.
		assert(v==true,'an option that takes no arguments must be given the value true')
		s = s..struct.pack('B',info_code)
		len = len + 1 + asserts(info_buf_sizes[k],'invalid option %s (missing buffer length)',k)
	end
	return s,len
end

local function info_buf_decode(buf, size)
	local t = {}
	local ofs = 1
	local info_code, info_name, info_decoder, info_body
	while true do
		assert(ofs <= size, 'unexpected end of info buffer')
		info_code,ofs = struct.unpack('B',buf,size,ofs)
		if info_end_code_lookup[info_code] then
			if info_code == info_end_codes.isc_info_end then
				break
			else
				error(string.format('error %s in info buffer',info_end_code_lookup[info_code]))
			end
		end
		info_name = asserts(info_code_lookup[info_code],'invalid info code %d returned by server',info_code)
		info_decoder = info_decoders[info_name]
		info_body = asserts(info_decoder,'missing decoder for info code %s',info_name)
		t[info_name],ofs = info_decoder(buf,size,ofs)
	end
	return t
end

local function query(request_opts, sbp_opts, buf, buf_size)
	local spb_s = query_spb_encode(spb_opts)
	local req_s, computed_buf_size = info_request_encode(request_opts)
	if buf then
		asserts(buf_size >= 1, 'buffer too small, min. size is %d bytes',1)
		--since we can't fill a larger buffer, better tell the user than dissilusion him later
		asserts(buf_size <= MAX_USHORT, 'buffer too large, max. size is %d bytes',MAX_USHORT)
	else
		buf_size = math.min(computed_buf_size, MAX_USHORT)
		buf = alien.buffer(buf_size)
	end
	fbtry(fbapi, sv, 'isc_service_query', svh, nil, spb_s and #spb_s or 0, spb_s, #req_s, req_s, buf_size, buf)
	info = info_buf_decode(buf, buf_size)
	return info, buf, buf_size --return buf,bufsize for eventual reuse of the buffer with another query()
end

function conn:query(...)
	return query(...)
end

