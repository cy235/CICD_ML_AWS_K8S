from testscase import test_cy235


def test_main():
    result = test_cy235.call_web_service()
    assert result.status_code == 200


def test_predict():
    result = test_cy235.post_music()
    assert result.status_code == 200
