test_pre () {
        ${config_backend}_change_var $config_sandbox swift_port 85859879464
}

test_while () {
        assert_num_procs "$subject_process" $num_procs_down
        assert_listening "$listen_address" 0
}

test_post () {
        test_post_die_during_startup 'error'
        debug_all_errors
}