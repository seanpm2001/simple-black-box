error="getaddrinfo"
source tests/generic_down_with_error.sh
test_pre () {
        ${config_backend}_change_var $config_sandbox swift_host '"foobar.notexist.dietertest.ny.vimeo.com"'
}