#[test_only]
module gacha::gacha_test;
// uncomment this line to import the module
// use gacha::gacha;

const ENotImplemented: u64 = 0;

#[test]
fun test_equality() {
    assert!(1==1, 1);
}

#[test, expected_failure(abort_code = ::gacha::gacha_test::ENotImplemented)]
fun test_gacha_fail() {
    abort ENotImplemented
}

