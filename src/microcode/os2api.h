/* -*-C-*-

Copyright (C) 1986, 1987, 1988, 1989, 1990, 1991, 1992, 1993, 1994,
    1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005,
    2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015
    Massachusetts Institute of Technology

This file is part of MIT/GNU Scheme.

MIT/GNU Scheme is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

MIT/GNU Scheme is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with MIT/GNU Scheme; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301,
USA.

*/

/* This flag, defined by "syscall.h", means to define the syscall
   enums normally defined by that file.  */
#ifdef DEFINE_OS2_SYSCALLS

enum syscall_names
{
  syscall_dos_alloc_mem,
  syscall_dos_alloc_shared_mem,
  syscall_dos_async_timer,
  syscall_dos_close,
  syscall_dos_close_event_sem,
  syscall_dos_close_mutex_sem,
  syscall_dos_close_queue,
  syscall_dos_copy,
  syscall_dos_create_dir,
  syscall_dos_create_event_sem,
  syscall_dos_create_mutex_sem,
  syscall_dos_create_pipe,
  syscall_dos_create_queue,
  syscall_dos_create_thread,
  syscall_dos_delete,
  syscall_dos_delete_dir,
  syscall_dos_dup_handle,
  syscall_dos_exec_pgm,
  syscall_dos_exit,
  syscall_dos_find_close,
  syscall_dos_find_first,
  syscall_dos_find_next,
  syscall_dos_free_mem,
  syscall_dos_get_info_blocks,
  syscall_dos_get_message,
  syscall_dos_get_named_shared_mem,
  syscall_dos_get_shared_mem,
  syscall_dos_give_shared_mem,
  syscall_dos_kill_process,
  syscall_dos_kill_thread,
  syscall_dos_move,
  syscall_dos_open,
  syscall_dos_post_event_sem,
  syscall_dos_query_current_dir,
  syscall_dos_query_current_disk,
  syscall_dos_query_fh_state,
  syscall_dos_query_file_info,
  syscall_dos_query_fs_attach,
  syscall_dos_query_fs_info,
  syscall_dos_query_h_type,
  syscall_dos_query_mem,
  syscall_dos_query_n_p_h_state,
  syscall_dos_query_path_info,
  syscall_dos_query_sys_info,
  syscall_dos_read,
  syscall_dos_read_queue,
  syscall_dos_release_mutex_sem,
  syscall_dos_request_mutex_sem,
  syscall_dos_reset_event_sem,
  syscall_dos_scan_env,
  syscall_dos_send_signal_exception,
  syscall_dos_set_current_dir,
  syscall_dos_set_default_disk,
  syscall_dos_set_fh_state,
  syscall_dos_set_file_ptr,
  syscall_dos_set_file_size,
  syscall_dos_set_max_fh,
  syscall_dos_set_mem,
  syscall_dos_set_path_info,
  syscall_dos_set_rel_max_fh,
  syscall_dos_start_timer,
  syscall_dos_stop_timer,
  syscall_dos_wait_child,
  syscall_dos_wait_event_sem,
  syscall_dos_write,
  syscall_dos_write_queue,
  syscall_beginthread,
  syscall_gmtime,
  syscall_kbd_char_in,
  syscall_localtime,
  syscall_malloc,
  syscall_mktime,
  syscall_realloc,
  syscall_time,
  syscall_vio_wrt_tty,

  /* Socket calls: */
  syscall_accept,
  syscall_bind,
  syscall_connect,
  syscall_gethostbyname,
  syscall_gethostname,
  syscall_listen,
  syscall_recv,
  syscall_send,
  syscall_socket,
  syscall_soclose
};

/* Machine-generated table, do not edit: */
enum syserr_names
{
  syserr_invalid_function,
  syserr_file_not_found,
  syserr_path_not_found,
  syserr_too_many_open_files,
  syserr_access_denied,
  syserr_invalid_handle,
  syserr_arena_trashed,
  syserr_not_enough_memory,
  syserr_invalid_block,
  syserr_bad_environment,
  syserr_bad_format,
  syserr_invalid_access,
  syserr_invalid_data,
  syserr_invalid_drive,
  syserr_current_directory,
  syserr_not_same_device,
  syserr_no_more_files,
  syserr_write_protect,
  syserr_bad_unit,
  syserr_not_ready,
  syserr_bad_command,
  syserr_crc,
  syserr_bad_length,
  syserr_seek,
  syserr_not_dos_disk,
  syserr_sector_not_found,
  syserr_out_of_paper,
  syserr_write_fault,
  syserr_read_fault,
  syserr_gen_failure,
  syserr_sharing_violation,
  syserr_lock_violation,
  syserr_wrong_disk,
  syserr_fcb_unavailable,
  syserr_sharing_buffer_exceeded,
  syserr_code_page_mismatched,
  syserr_handle_eof,
  syserr_handle_disk_full,
  syserr_not_supported,
  syserr_rem_not_list,
  syserr_dup_name,
  syserr_bad_netpath,
  syserr_network_busy,
  syserr_dev_not_exist,
  syserr_too_many_cmds,
  syserr_adap_hdw_err,
  syserr_bad_net_resp,
  syserr_unexp_net_err,
  syserr_bad_rem_adap,
  syserr_printq_full,
  syserr_no_spool_space,
  syserr_print_cancelled,
  syserr_netname_deleted,
  syserr_network_access_denied,
  syserr_bad_dev_type,
  syserr_bad_net_name,
  syserr_too_many_names,
  syserr_too_many_sess,
  syserr_sharing_paused,
  syserr_req_not_accep,
  syserr_redir_paused,
  syserr_sbcs_att_write_prot,
  syserr_sbcs_general_failure,
  syserr_xga_out_memory,
  syserr_file_exists,
  syserr_dup_fcb,
  syserr_cannot_make,
  syserr_fail_i24,
  syserr_out_of_structures,
  syserr_already_assigned,
  syserr_invalid_password,
  syserr_invalid_parameter,
  syserr_net_write_fault,
  syserr_no_proc_slots,
  syserr_not_frozen,
  syserr_tstovfl,
  syserr_tstdup,
  syserr_no_items,
  syserr_interrupt,
  syserr_device_in_use,
  syserr_too_many_semaphores,
  syserr_excl_sem_already_owned,
  syserr_sem_is_set,
  syserr_too_many_sem_requests,
  syserr_invalid_at_interrupt_time,
  syserr_sem_owner_died,
  syserr_sem_user_limit,
  syserr_disk_change,
  syserr_drive_locked,
  syserr_broken_pipe,
  syserr_open_failed,
  syserr_buffer_overflow,
  syserr_disk_full,
  syserr_no_more_search_handles,
  syserr_invalid_target_handle,
  syserr_protection_violation,
  syserr_viokbd_request,
  syserr_invalid_category,
  syserr_invalid_verify_switch,
  syserr_bad_driver_level,
  syserr_call_not_implemented,
  syserr_sem_timeout,
  syserr_insufficient_buffer,
  syserr_invalid_name,
  syserr_invalid_level,
  syserr_no_volume_label,
  syserr_mod_not_found,
  syserr_proc_not_found,
  syserr_wait_no_children,
  syserr_child_not_complete,
  syserr_direct_access_handle,
  syserr_negative_seek,
  syserr_seek_on_device,
  syserr_is_join_target,
  syserr_is_joined,
  syserr_is_substed,
  syserr_not_joined,
  syserr_not_substed,
  syserr_join_to_join,
  syserr_subst_to_subst,
  syserr_join_to_subst,
  syserr_subst_to_join,
  syserr_busy_drive,
  syserr_same_drive,
  syserr_dir_not_root,
  syserr_dir_not_empty,
  syserr_is_subst_path,
  syserr_is_join_path,
  syserr_path_busy,
  syserr_is_subst_target,
  syserr_system_trace,
  syserr_invalid_event_count,
  syserr_too_many_muxwaiters,
  syserr_invalid_list_format,
  syserr_label_too_long,
  syserr_too_many_tcbs,
  syserr_signal_refused,
  syserr_discarded,
  syserr_not_locked,
  syserr_bad_threadid_addr,
  syserr_bad_arguments,
  syserr_bad_pathname,
  syserr_signal_pending,
  syserr_uncertain_media,
  syserr_max_thrds_reached,
  syserr_monitors_not_supported,
  syserr_unc_driver_not_installed,
  syserr_lock_failed,
  syserr_swapio_failed,
  syserr_swapin_failed,
  syserr_busy,
  syserr_cancel_violation,
  syserr_atomic_lock_not_supported,
  syserr_read_locks_not_supported,
  syserr_invalid_segment_number,
  syserr_invalid_callgate,
  syserr_invalid_ordinal,
  syserr_already_exists,
  syserr_no_child_process,
  syserr_child_alive_nowait,
  syserr_invalid_flag_number,
  syserr_sem_not_found,
  syserr_invalid_starting_codeseg,
  syserr_invalid_stackseg,
  syserr_invalid_moduletype,
  syserr_invalid_exe_signature,
  syserr_exe_marked_invalid,
  syserr_bad_exe_format,
  syserr_iterated_data_exceeds_64k,
  syserr_invalid_minallocsize,
  syserr_dynlink_from_invalid_ring,
  syserr_iopl_not_enabled,
  syserr_invalid_segdpl,
  syserr_autodataseg_exceeds_64k,
  syserr_ring2seg_must_be_movable,
  syserr_reloc_chain_xeeds_seglim,
  syserr_infloop_in_reloc_chain,
  syserr_envvar_not_found,
  syserr_not_current_ctry,
  syserr_no_signal_sent,
  syserr_filename_exced_range,
  syserr_ring2_stack_in_use,
  syserr_meta_expansion_too_long,
  syserr_invalid_signal_number,
  syserr_thread_1_inactive,
  syserr_info_not_avail,
  syserr_locked,
  syserr_bad_dynalink,
  syserr_too_many_modules,
  syserr_nesting_not_allowed,
  syserr_cannot_shrink,
  syserr_zombie_process,
  syserr_stack_in_high_memory,
  syserr_invalid_exitroutine_ring,
  syserr_getbuf_failed,
  syserr_flushbuf_failed,
  syserr_transfer_too_long,
  syserr_forcenoswap_failed,
  syserr_smg_no_target_window,
  syserr_no_children,
  syserr_invalid_screen_group,
  syserr_bad_pipe,
  syserr_pipe_busy,
  syserr_no_data,
  syserr_pipe_not_connected,
  syserr_more_data,
  syserr_vc_disconnected,
  syserr_circularity_requested,
  syserr_directory_in_cds,
  syserr_invalid_fsd_name,
  syserr_invalid_path,
  syserr_invalid_ea_name,
  syserr_ea_list_inconsistent,
  syserr_ea_list_too_long,
  syserr_no_meta_match,
  syserr_findnotify_timeout,
  syserr_no_more_items,
  syserr_search_struc_reused,
  syserr_char_not_found,
  syserr_too_much_stack,
  syserr_invalid_attr,
  syserr_invalid_starting_ring,
  syserr_invalid_dll_init_ring,
  syserr_cannot_copy,
  syserr_directory,
  syserr_oplocked_file,
  syserr_oplock_thread_exists,
  syserr_volume_changed,
  syserr_findnotify_handle_in_use,
  syserr_findnotify_handle_closed,
  syserr_notify_object_removed,
  syserr_already_shutdown,
  syserr_eas_didnt_fit,
  syserr_ea_file_corrupt,
  syserr_ea_table_full,
  syserr_invalid_ea_handle,
  syserr_no_cluster,
  syserr_create_ea_file,
  syserr_cannot_open_ea_file,
  syserr_eas_not_supported,
  syserr_need_eas_found,
  syserr_duplicate_handle,
  syserr_duplicate_name,
  syserr_empty_muxwait,
  syserr_mutex_owned,
  syserr_not_owner,
  syserr_param_too_small,
  syserr_too_many_handles,
  syserr_too_many_opens,
  syserr_wrong_type,
  syserr_unused_code,
  syserr_thread_not_terminated,
  syserr_init_routine_failed,
  syserr_module_in_use,
  syserr_not_enough_watchpoints,
  syserr_too_many_posts,
  syserr_already_posted,
  syserr_already_reset,
  syserr_sem_busy,
  syserr_invalid_procid,
  syserr_invalid_pdelta,
  syserr_not_descendant,
  syserr_not_session_manager,
  syserr_invalid_pclass,
  syserr_invalid_scope,
  syserr_invalid_threadid,
  syserr_dossub_shrink,
  syserr_dossub_nomem,
  syserr_dossub_overlap,
  syserr_dossub_badsize,
  syserr_dossub_badflag,
  syserr_dossub_badselector,
  syserr_mr_msg_too_long,
  syserr_mr_mid_not_found,
  syserr_mr_un_acc_msgf,
  syserr_mr_inv_msgf_format,
  syserr_mr_inv_ivcount,
  syserr_mr_un_perform,
  syserr_ts_wakeup,
  syserr_ts_semhandle,
  syserr_ts_notimer,
  syserr_ts_handle,
  syserr_ts_datetime,
  syserr_sys_internal,
  syserr_que_current_name,
  syserr_que_proc_not_owned,
  syserr_que_proc_owned,
  syserr_que_duplicate,
  syserr_que_element_not_exist,
  syserr_que_no_memory,
  syserr_que_invalid_name,
  syserr_que_invalid_priority,
  syserr_que_invalid_handle,
  syserr_que_link_not_found,
  syserr_que_memory_error,
  syserr_que_prev_at_end,
  syserr_que_proc_no_access,
  syserr_que_empty,
  syserr_que_name_not_exist,
  syserr_que_not_initialized,
  syserr_que_unable_to_access,
  syserr_que_unable_to_add,
  syserr_que_unable_to_init,
  syserr_vio_invalid_mask,
  syserr_vio_ptr,
  syserr_vio_aptr,
  syserr_vio_rptr,
  syserr_vio_cptr,
  syserr_vio_lptr,
  syserr_vio_mode,
  syserr_vio_width,
  syserr_vio_attr,
  syserr_vio_row,
  syserr_vio_col,
  syserr_vio_toprow,
  syserr_vio_botrow,
  syserr_vio_rightcol,
  syserr_vio_leftcol,
  syserr_scs_call,
  syserr_scs_value,
  syserr_vio_wait_flag,
  syserr_vio_unlock,
  syserr_sgs_not_session_mgr,
  syserr_smg_invalid_session_id,
  syserr_smg_no_sessions,
  syserr_smg_session_not_found,
  syserr_smg_set_title,
  syserr_kbd_parameter,
  syserr_kbd_no_device,
  syserr_kbd_invalid_iowait,
  syserr_kbd_invalid_length,
  syserr_kbd_invalid_echo_mask,
  syserr_kbd_invalid_input_mask,
  syserr_mon_invalid_parms,
  syserr_mon_invalid_devname,
  syserr_mon_invalid_handle,
  syserr_mon_buffer_too_small,
  syserr_mon_buffer_empty,
  syserr_mon_data_too_large,
  syserr_mouse_no_device,
  syserr_mouse_inv_handle,
  syserr_mouse_inv_parms,
  syserr_mouse_cant_reset,
  syserr_mouse_display_parms,
  syserr_mouse_inv_module,
  syserr_mouse_inv_entry_pt,
  syserr_mouse_inv_mask,
  syserr_mouse_no_data,
  syserr_mouse_ptr_drawn,
  syserr_invalid_frequency,
  syserr_nls_no_country_file,
  syserr_nls_open_failed,
  syserr_no_country_or_codepage,
  syserr_nls_table_truncated,
  syserr_nls_bad_type,
  syserr_nls_type_not_found,
  syserr_vio_smg_only,
  syserr_vio_invalid_asciiz,
  syserr_vio_deregister,
  syserr_vio_no_popup,
  syserr_vio_existing_popup,
  syserr_kbd_smg_only,
  syserr_kbd_invalid_asciiz,
  syserr_kbd_invalid_mask,
  syserr_kbd_register,
  syserr_kbd_deregister,
  syserr_mouse_smg_only,
  syserr_mouse_invalid_asciiz,
  syserr_mouse_invalid_mask,
  syserr_mouse_register,
  syserr_mouse_deregister,
  syserr_smg_bad_action,
  syserr_smg_invalid_call,
  syserr_scs_sg_notfound,
  syserr_scs_not_shell,
  syserr_vio_invalid_parms,
  syserr_vio_function_owned,
  syserr_vio_return,
  syserr_scs_invalid_function,
  syserr_scs_not_session_mgr,
  syserr_vio_register,
  syserr_vio_no_mode_thread,
  syserr_vio_no_save_restore_thd,
  syserr_vio_in_bg,
  syserr_vio_illegal_during_popup,
  syserr_smg_not_baseshell,
  syserr_smg_bad_statusreq,
  syserr_que_invalid_wait,
  syserr_vio_lock,
  syserr_mouse_invalid_iowait,
  syserr_vio_invalid_handle,
  syserr_vio_illegal_during_lock,
  syserr_vio_invalid_length,
  syserr_kbd_invalid_handle,
  syserr_kbd_no_more_handle,
  syserr_kbd_cannot_create_kcb,
  syserr_kbd_codepage_load_incompl,
  syserr_kbd_invalid_codepage_id,
  syserr_kbd_no_codepage_support,
  syserr_kbd_focus_required,
  syserr_kbd_focus_already_active,
  syserr_kbd_keyboard_busy,
  syserr_kbd_invalid_codepage,
  syserr_kbd_unable_to_focus,
  syserr_smg_session_non_select,
  syserr_smg_session_not_foregrnd,
  syserr_smg_session_not_parent,
  syserr_smg_invalid_start_mode,
  syserr_smg_invalid_related_opt,
  syserr_smg_invalid_bond_option,
  syserr_smg_invalid_select_opt,
  syserr_smg_start_in_background,
  syserr_smg_invalid_stop_option,
  syserr_smg_bad_reserve,
  syserr_smg_process_not_parent,
  syserr_smg_invalid_data_length,
  syserr_smg_not_bound,
  syserr_smg_retry_sub_alloc,
  syserr_kbd_detached,
  syserr_vio_detached,
  syserr_mou_detached,
  syserr_vio_font,
  syserr_vio_user_font,
  syserr_vio_bad_cp,
  syserr_vio_no_cp,
  syserr_vio_na_cp,
  syserr_invalid_code_page,
  syserr_cplist_too_small,
  syserr_cp_not_moved,
  syserr_mode_switch_init,
  syserr_code_page_not_found,
  syserr_unexpected_slot_returned,
  syserr_smg_invalid_trace_option,
  syserr_vio_internal_resource,
  syserr_vio_shell_init,
  syserr_smg_no_hard_errors,
  syserr_cp_switch_incomplete,
  syserr_vio_transparent_popup,
  syserr_critsec_overflow,
  syserr_critsec_underflow,
  syserr_vio_bad_reserve,
  syserr_invalid_address,
  syserr_zero_selectors_requested,
  syserr_not_enough_selectors_ava,
  syserr_invalid_selector,
  syserr_smg_invalid_program_type,
  syserr_smg_invalid_pgm_control,
  syserr_smg_invalid_inherit_opt,
  syserr_vio_extended_sg,
  syserr_vio_not_pres_mgr_sg,
  syserr_vio_shield_owned,
  syserr_vio_no_more_handles,
  syserr_vio_see_error_log,
  syserr_vio_associated_dc,
  syserr_kbd_no_console,
  syserr_mouse_no_console,
  syserr_mouse_invalid_handle,
  syserr_smg_invalid_debug_parms,
  syserr_kbd_extended_sg,
  syserr_mou_extended_sg,
  syserr_smg_invalid_icon_file,
  syserr_trc_pid_non_existent,
  syserr_trc_count_active,
  syserr_trc_suspended_by_count,
  syserr_trc_count_inactive,
  syserr_trc_count_reached,
  syserr_no_mc_trace,
  syserr_mc_trace,
  syserr_trc_count_zero,
  syserr_smg_too_many_dds,
  syserr_smg_invalid_notification,
  syserr_lf_invalid_function,
  syserr_lf_not_avail,
  syserr_lf_suspended,
  syserr_lf_buf_too_small,
  syserr_lf_buffer_full,
  syserr_lf_invalid_record,
  syserr_lf_invalid_service,
  syserr_lf_general_failure,
  syserr_lf_invalid_id,
  syserr_lf_invalid_handle,
  syserr_lf_no_id_avail,
  syserr_lf_template_area_full,
  syserr_lf_id_in_use,
  syserr_mou_not_initialized,
  syserr_mouinitreal_done,
  syserr_dossub_corrupted,
  syserr_mouse_caller_not_subsys,
  syserr_arithmetic_overflow,
  syserr_tmr_no_device,
  syserr_tmr_invalid_time,
  syserr_pvw_invalid_entity,
  syserr_pvw_invalid_entity_type,
  syserr_pvw_invalid_spec,
  syserr_pvw_invalid_range_type,
  syserr_pvw_invalid_counter_blk,
  syserr_pvw_invalid_text_blk,
  syserr_prf_not_initialized,
  syserr_prf_already_initialized,
  syserr_prf_not_started,
  syserr_prf_already_started,
  syserr_prf_timer_out_of_range,
  syserr_prf_timer_reset,
  syserr_vdd_lock_useage_denied,
  syserr_timeout,
  syserr_vdm_down,
  syserr_vdm_limit,
  syserr_vdd_not_found,
  syserr_invalid_caller,
  syserr_pid_mismatch,
  syserr_invalid_vdd_handle,
  syserr_vlpt_no_spooler,
  syserr_vcom_device_busy,
  syserr_vlpt_device_busy,
  syserr_nesting_too_deep,
  syserr_vdd_missing,
  syserr_bidi_invalid_length,
  syserr_bidi_invalid_increment,
  syserr_bidi_invalid_combination,
  syserr_bidi_invalid_reserved,
  syserr_bidi_invalid_effect,
  syserr_bidi_invalid_csdrec,
  syserr_bidi_invalid_csdstate,
  syserr_bidi_invalid_level,
  syserr_bidi_invalid_type_support,
  syserr_bidi_invalid_orientation,
  syserr_bidi_invalid_num_shape,
  syserr_bidi_invalid_csd,
  syserr_bidi_no_support,
  syserr_bidi_rw_incomplete,
  syserr_imp_invalid_parm,
  syserr_imp_invalid_length,
  syserr_hpfs_disk_error_warn,
  syserr_mon_bad_buffer,
  syserr_module_corrupted,
  syserr_sm_outof_swapfile,
  syserr_lf_timeout,
  syserr_lf_suspend_success,
  syserr_lf_resume_success,
  syserr_lf_redirect_success,
  syserr_lf_redirect_failure,
  syserr_swapper_not_active,
  syserr_invalid_swapid,
  syserr_ioerr_swap_file,
  syserr_swap_table_full,
  syserr_swap_file_full,
  syserr_cant_init_swapper,
  syserr_swapper_already_init,
  syserr_pmm_insufficient_memory,
  syserr_pmm_invalid_flags,
  syserr_pmm_invalid_address,
  syserr_pmm_lock_failed,
  syserr_pmm_unlock_failed,
  syserr_pmm_move_incomplete,
  syserr_ucom_drive_renamed,
  syserr_ucom_filename_truncated,
  syserr_ucom_buffer_length,
  syserr_mon_chain_handle,
  syserr_mon_not_registered,
  syserr_smg_already_top,
  syserr_pmm_arena_modified,
  syserr_smg_printer_open,
  syserr_pmm_set_flags_failed,
  syserr_invalid_dos_dd,
  syserr_blocked,
  syserr_noblock,
  syserr_instance_shared,
  syserr_no_object,
  syserr_partial_attach,
  syserr_incache,
  syserr_swap_io_problems,
  syserr_crosses_object_boundary,
  syserr_longlock,
  syserr_shortlock,
  syserr_uvirtlock,
  syserr_aliaslock,
  syserr_alias,
  syserr_no_more_handles,
  syserr_scan_terminated,
  syserr_terminator_not_found,
  syserr_not_direct_child,
  syserr_delay_free,
  syserr_guardpage,
  syserr_swaperror,
  syserr_ldrerror,
  syserr_nomemory,
  syserr_noaccess,
  syserr_no_dll_term,
  syserr_cpsio_code_page_invalid,
  syserr_cpsio_no_spooler,
  syserr_cpsio_font_id_invalid,
  syserr_cpsio_internal_error,
  syserr_cpsio_invalid_ptr_name,
  syserr_cpsio_not_active,
  syserr_cpsio_pid_full,
  syserr_cpsio_pid_not_found,
  syserr_cpsio_read_ctl_seq,
  syserr_cpsio_read_fnt_def,
  syserr_cpsio_write_error,
  syserr_cpsio_write_full_error,
  syserr_cpsio_write_handle_bad,
  syserr_cpsio_swit_load,
  syserr_cpsio_inv_command,
  syserr_cpsio_no_font_swit,
  syserr_entry_is_callgate,

  /* Socket errors: */
  syserr_socket_perm,
  syserr_socket_srch,
  syserr_socket_intr,
  syserr_socket_nxio,
  syserr_socket_badf,
  syserr_socket_acces,
  syserr_socket_fault,
  syserr_socket_inval,
  syserr_socket_mfile,
  syserr_socket_pipe,
  syserr_socket_os2err,
  syserr_socket_wouldblock,
  syserr_socket_inprogress,
  syserr_socket_already,
  syserr_socket_notsock,
  syserr_socket_destaddrreq,
  syserr_socket_msgsize,
  syserr_socket_prototype,
  syserr_socket_noprotoopt,
  syserr_socket_protonosupport,
  syserr_socket_socktnosupport,
  syserr_socket_opnotsupp,
  syserr_socket_pfnosupport,
  syserr_socket_afnosupport,
  syserr_socket_addrinuse,
  syserr_socket_addrnotavail,
  syserr_socket_netdown,
  syserr_socket_netunreach,
  syserr_socket_netreset,
  syserr_socket_connaborted,
  syserr_socket_connreset,
  syserr_socket_nobufs,
  syserr_socket_isconn,
  syserr_socket_notconn,
  syserr_socket_shutdown,
  syserr_socket_toomanyrefs,
  syserr_socket_timedout,
  syserr_socket_connrefused,
  syserr_socket_loop,
  syserr_socket_nametoolong,
  syserr_socket_hostdown,
  syserr_socket_hostunreach,
  syserr_socket_notempty,

  syserr_unknown
};

#define syserr_not_enough_space syserr_not_enough_memory

#else /* not DEFINE_OS2_SYSCALLS */

#ifndef SCM_OS2API_H
#define SCM_OS2API_H

/* STD_API_CALL cannot be written as a specialization of XTD_API_CALL,
   because that causes the `proc' argument to be expanded, which
   screws up the generation of `syscall_ ## proc'.  */

#define STD_API_CALL(proc, args)					\
{									\
  while (1)								\
    {									\
      APIRET rc = (proc args);						\
      if (rc == NO_ERROR)						\
	break;								\
      if (rc != ERROR_INTERRUPT)					\
	OS2_error_system_call (rc, syscall_ ## proc);			\
    }									\
}

#define XTD_API_CALL(proc, args, if_error)				\
{									\
  while (1)								\
    {									\
      APIRET rc = (proc args);						\
      if (rc == NO_ERROR)						\
	break;								\
      if (rc != ERROR_INTERRUPT)					\
	{								\
	  if_error;							\
	  OS2_error_system_call (rc, syscall_ ## proc);			\
	}								\
    }									\
}

#define dos_alloc_mem		DosAllocMem
#define dos_alloc_shared_mem	DosAllocSharedMem
#define dos_async_timer		DosAsyncTimer
#define dos_close		DosClose
#define dos_close_event_sem	DosCloseEventSem
#define dos_close_mutex_sem	DosCloseMutexSem
#define dos_close_queue		DosCloseQueue
#define dos_copy		DosCopy
#define dos_create_dir		DosCreateDir
#define dos_create_event_sem	DosCreateEventSem
#define dos_create_mutex_sem	DosCreateMutexSem
#define dos_create_pipe		DosCreatePipe
#define dos_create_queue	DosCreateQueue
#define dos_create_thread	DosCreateThread
#define dos_delete		DosDelete
#define dos_delete_dir		DosDeleteDir
#define dos_dup_handle		DosDupHandle
#define dos_exec_pgm		DosExecPgm
#define dos_exit		DosExit
#define dos_find_close		DosFindClose
#define dos_find_first		DosFindFirst
#define dos_find_next		DosFindNext
#define dos_free_mem		DosFreeMem
#define dos_get_info_blocks	DosGetInfoBlocks
#define dos_get_message		DosGetMessage
#define dos_get_named_shared_mem DosGetNamedSharedMem
#define dos_get_shared_mem	DosGetSharedMem
#define dos_give_shared_mem	DosGiveSharedMem
#define dos_kill_process	DosKillProcess
#define dos_kill_thread		DosKillThread
#define dos_move		DosMove
#define dos_open		DosOpen
#define dos_post_event_sem	DosPostEventSem
#define dos_query_current_dir	DosQueryCurrentDir
#define dos_query_current_disk	DosQueryCurrentDisk
#define dos_query_fh_state	DosQueryFHState
#define dos_query_file_info	DosQueryFileInfo
#define dos_query_fs_attach	DosQueryFSAttach
#define dos_query_fs_info	DosQueryFSInfo
#define dos_query_h_type	DosQueryHType
#define dos_query_mem		DosQueryMem
#define dos_query_n_p_h_state	DosQueryNPHState
#define dos_query_path_info	DosQueryPathInfo
#define dos_query_sys_info	DosQuerySysInfo
#define dos_read		DosRead
#define dos_read_queue		DosReadQueue
#define dos_release_mutex_sem	DosReleaseMutexSem
#define dos_request_mutex_sem	DosRequestMutexSem
#define dos_reset_event_sem	DosResetEventSem
#define dos_scan_env		DosScanEnv
#define dos_send_signal_exception DosSendSignalException
#define dos_set_current_dir	DosSetCurrentDir
#define dos_set_default_disk	DosSetDefaultDisk
#define dos_set_fh_state	DosSetFHState
#define dos_set_file_ptr	DosSetFilePtr
#define dos_set_file_size	DosSetFileSize
#define dos_set_max_fh		DosSetMaxFH
#define dos_set_mem		DosSetMem
#define dos_set_path_info	DosSetPathInfo
#define dos_set_rel_max_fh	DosSetRelMaxFH
#define dos_start_timer		DosStartTimer
#define dos_stop_timer		DosStopTimer
#define dos_wait_child		DosWaitChild
#define dos_wait_event_sem	DosWaitEventSem
#define dos_write		DosWrite
#define dos_write_queue		DosWriteQueue
#define kbd_char_in		KbdCharIn
#define vio_wrt_tty		VioWrtTTY

#ifdef SCM_OS2TOP_C

static char * syscall_names_table [] =
{
  "dos-alloc-mem",
  "dos-alloc-shared-mem",
  "dos-async-timer",
  "dos-close",
  "dos-close-event-sem",
  "dos-close-mutex-sem",
  "dos-close-queue",
  "dos-copy",
  "dos-create-dir",
  "dos-create-event-sem",
  "dos-create-mutex-sem",
  "dos-create-pipe",
  "dos-create-queue",
  "dos-create-thread",
  "dos-delete",
  "dos-delete-dir",
  "dos-dup-handle",
  "dos-exec-pgm",
  "dos-exit",
  "dos-find-close",
  "dos-find-first",
  "dos-find-next",
  "dos-free-mem",
  "dos-get-info-blocks",
  "dos-get-message",
  "dos-get-named-shared-mem",
  "dos-get-shared-mem",
  "dos-give-shared-mem",
  "dos-kill-process",
  "dos-kill-thread",
  "dos-move",
  "dos-open",
  "dos-post-event-sem",
  "dos-query-current-dir",
  "dos-query-current-disk",
  "dos-query-fh-state",
  "dos-query-file-info",
  "dos-query-fs-attach",
  "dos-query-fs-info",
  "dos-query-h-type",
  "dos-query-mem",
  "dos-query-n-p-h-state",
  "dos-query-path-info",
  "dos-query-sys-info",
  "dos-read",
  "dos-read-queue",
  "dos-release-mutex-sem",
  "dos-request-mutex-sem",
  "dos-reset-event-sem",
  "dos-scan-env",
  "dos-send-signal-exception",
  "dos-set-current-dir",
  "dos-set-default-disk",
  "dos-set-fh-state",
  "dos-set-file-ptr",
  "dos-set-file-size",
  "dos-set-max-fh",
  "dos-set-mem",
  "dos-set-path-info",
  "dos-set-rel-max-fh",
  "dos-start-timer",
  "dos-stop-timer",
  "dos-wait-child",
  "dos-wait-event-sem",
  "dos-write",
  "dos-write-queue",
  "beginthread",
  "gmtime",
  "kbd-char-in",
  "localtime",
  "malloc",
  "mktime",
  "realloc",
  "time",
  "vio-wrt-tty",

  /* Socket calls: */
  "accept",
  "bind",
  "connect",
  "get-host-by-name",
  "get-host-name",
  "listen",
  "recv",
  "send",
  "socket",
  "soclose"
};

#endif /* SCM_OS2TOP_C */

#endif /* SCM_OS2API_H */
#endif /* not DEFINE_OS2_SYSCALLS */
