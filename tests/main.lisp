(defpackage color-bot/tests/main
  (:use :cl
        :color-bot
        :rove))
(in-package :color-bot/tests/main)

;; NOTE: To run this test file, execute `(asdf:test-system :color-bot)' in your Lisp.

(deftest test-target-1
  (testing "should (= 1 1) to be true"
    (ok (= 1 1))))
