;;;; package.lisp

(defpackage #:color-bot
  (:use #:cl)
  (:import-from #:cl-telegram-bot
   :make-bot
   :get-updates
   :send-message
   :send-photo
   :access
   :endpoint)
  (:import-from #:drakma
   :http-request)
  (:import-from #:alexandria
   :when-let
   :if-let)
  (:import-from #:cl-ppcre
   :create-scanner
   :scan)
  (:import-from #:cl-json
   :decode-json-from-string)
  (:import-from #:zpng
   :start-png
   :write-pixel
   :finish-png
   :pixel-streamed-png))
