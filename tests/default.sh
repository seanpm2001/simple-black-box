# this default test is a good starting point for a simple json-configured 3-process daemon that listens on tcp:8080
# this is supposed to represent a default configuration, where everything will just work. other tests can then
# override specific things to introduce different behavior and assert accordingly.

# callback, triggered at least from inside the main app
debug_all_errors () {
        grep -Ri --color=never error $stdout $stderr $log 2>/dev/null | debug_stream "all errors:"
}

# needed vars: $src, $test, $project
# test identifier, sandbox, config and i/o locations
test_id="$(cd "$src" && git describe --always --dirty)_test_${test}"
sandbox=/tmp/$project_$test_id # mirror of src which we can pollute with logfiles and modifications
stdout=$sandbox/stdout
stderr=$sandbox/stderr
log= # optional
config_backend=json
config_sandbox=$sandbox/node_modules/${project}conf.json
config_src=$src/node_modules/${project}conf.json

# probe / assertion parameters
num_procs_up=3
num_procs_down=0
listen_address=tcp:8080
# node cluster doesn't kill children properly yet https://github.com/joyent/node/pull/2908
# so until then, match both master and workers
# 'pgrep -f' compatible regex to capture all our "subject processes"
subject_process="^node /usr/.*/coffee ($sandbox/)?$project.coffee"
http_pattern="port 80 and host localhost"
# command to start the program from inside the sandbox (ignoring stdout/stderr here)
process_launch="coffee $project.coffee"

test_prepare_sandbox () {
        mkdir -p $sandbox
        rsync -au --delete $src/ $sandbox/
        assert_exitcode test -f $sandbox/$project.coffee
}

# here you can alter the sandbox, modify config settings etc.
test_pre () {
        true
}

test_run () {
        set_http_probe "$http_pattern"
        cd $sandbox
        $process_launch > $stdout 2> $stderr &
        # allow processes to actually start and do all their config, bootstrapping, etc
        sleep 3s
        cd - >/dev/null
}

# do assertions which are executed while the subject process should be up and running
test_while () {
        assert_num_procs "$subject_process" $num_procs_up
        assert_listening "$listen_address" 1
}

test_teardown () {
        kill_graceful "$subject_process"
        assert_num_procs "$subject_process" $num_procs_down
        remove_http_probe "$http_pattern"
        assert_listening "$listen_address" 0
}

# perform operations which you don't want to be catched by the http probe and/or which are better suited when the subject process is down
test_post () {
        assert_no_errors $stdout $stderr $log
        debug_all_errors
}
