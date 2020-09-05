(defsystem "color-bot"
  :version "0.1.0"
  :author ""
  :license ""
  :depends-on ("alexandria"
               "zpng"
               "cl-json"
               "cl-ppcre"
               "drakma"
               "uiop"
               "cl-telegram-bot"
               "flexi-streams"
               "cl-arrows")
  :components ((:module "src"
                :components
                ((:file "main"))))
  :description ""
  ;; :in-order-to ((test-op (test-op "color-bot/tests")))
  )

;; (defsystem "color-bot/tests"
;;   :author ""
;;   :license ""
;;   :depends-on ("color-bot"
;;                "rove")
;;   :components ((:module "tests"
;;                 :components
;;                 ((:file "main"))))
;;   :description "Test system for color-bot"
;;   :perform (test-op (op c) (symbol-call :rove :run c)))
