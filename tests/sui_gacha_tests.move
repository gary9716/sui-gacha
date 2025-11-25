
#[test_only]
module sui_gacha::sui_gacha_tests;
// uncomment this line to import the module
// use sui_gacha::sui_gacha;

const ENotImplemented: u64 = 0;

#[test]
fun test_equality() {
    assert!(1==1, 1);
}

#[test, expected_failure(abort_code = ::sui_gacha::sui_gacha_tests::ENotImplemented)]
fun test_sui_gacha_fail() {
    abort ENotImplemented
}

