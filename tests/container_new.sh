container=test_$RANDOM
test_pre () {
        debug "deleting container $container, should it exist: $(swift $swift_args delete $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container 0
        ${config_backend}_change_var $config_sandbox swift_container "\"$container\""
}

test_post () {
        assert_container_exists "$swift_args" $container
        debug "deleting container $container: $(swift $swift_args delete $container 2>&1)"
        internal=1 assert_container_exists "$swift_args" $container 0
        assert_http_response_to "^PUT" 201 1
        assert_num_http_requests "^PUT" 1 1
        assert_http_response_to 'GET /auth/v1.0' 200
        assert_num_http_requests 'GET /auth/v1.0' $num_procs_up $num_procs_up # every process will do an auth
        assert_no_errors $stdout $stderr $log
        assert_pattern "container.*$container.*already existed" 0 $stdout $stderr $log
        assert_pattern "created.*$container" 1 $stdout $stderr $log
        debug_all_errors
}