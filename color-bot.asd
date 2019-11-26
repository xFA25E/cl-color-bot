;;;; color-bot.asd

(asdf:defsystem #:color-bot
  :description "Telegram Color Bot"
  :author ""
  :license ""
  :version "0.0.1"
  :serial t
  :depends-on (#:cl-telegram-bot #:cl-json #:drakma #:alexandria #:cl-ppcre
                                 #:zpng)
  :components ((:file "package")
               (:file "color-bot")))
