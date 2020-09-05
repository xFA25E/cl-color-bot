(defpackage color-bot
  (:use :cl)
  (:import-from #:cl-telegram-bot
                #:make-bot
                #:get-updates
                #:send-message
                #:send-photo
                #:access
                #:endpoint)
  (:import-from #:drakma :http-request)
  (:import-from #:alexandria
                #:when-let
                #:if-let
                #:hash-table-keys
                #:hash-table-alist
                #:alist-hash-table)
  (:import-from #:cl-ppcre #:create-scanner #:scan-to-strings #:regex-replace)
  (:import-from #:cl-json #:decode-json-from-string)
  (:import-from #:zpng #:start-png #:write-pixel #:finish-png #:pixel-streamed-png)
  (:export #:main #:start-bot #:stop-bot))
(in-package :color-bot)

(defparameter *cached-photos-filename* #p"cached-photos.lisp")

(defun save-photos ()
  (with-open-file (out *cached-photos-filename*
                       :direction :output
                       :if-exists :supersede)
    (with-standard-io-syntax
      (print (hash-table-alist *cached-photos*) out))))

(defun load-photos ()
  (with-open-file (in *cached-photos-filename* :if-does-not-exist nil)
    (when in
      (with-standard-io-syntax
        (let ((*read-eval* nil))
          (alist-hash-table (read in) :test #'equalp))))))

(defparameter json:*json-symbols-package* :color-bot)

(defparameter *bot-token* (uiop:getenv "TELEGRAM_BOT_TOKEN"))

(defparameter *cached-photos* (or (load-photos) (make-hash-table :test #'equalp)))

(defparameter *hex-color-scanner* (create-scanner "\\B#(?i:[a-f0-9]{3}){1,2}\\b"))
(defparameter *hex-color-normalize-scanner* "^(?i)#([a-f0-9])([a-f0-9])([a-f0-9])$")

(defparameter *web-colors*
  (let* ((color-pairs
           ;; Copied from emacs's SHR-COLOR-HTML-COLORS-ALIST
           '(("AliceBlue"            . "#F0F8FF")
             ("AntiqueWhite"         . "#FAEBD7")
             ("Aqua"                 . "#00FFFF")
             ("Aquamarine"           . "#7FFFD4")
             ("Azure"                . "#F0FFFF")
             ("Beige"                . "#F5F5DC")
             ("Bisque"               . "#FFE4C4")
             ("Black"                . "#000000")
             ("BlanchedAlmond"       . "#FFEBCD")
             ("Blue"                 . "#0000FF")
             ("BlueViolet"           . "#8A2BE2")
             ("Brown"                . "#A52A2A")
             ("BurlyWood"            . "#DEB887")
             ("CadetBlue"            . "#5F9EA0")
             ("Chartreuse"           . "#7FFF00")
             ("Chocolate"            . "#D2691E")
             ("Coral"                . "#FF7F50")
             ("CornflowerBlue"       . "#6495ED")
             ("Cornsilk"             . "#FFF8DC")
             ("Crimson"              . "#DC143C")
             ("Cyan"                 . "#00FFFF")
             ("DarkBlue"             . "#00008B")
             ("DarkCyan"             . "#008B8B")
             ("DarkGoldenRod"        . "#B8860B")
             ("DarkGray"             . "#A9A9A9")
             ("DarkGrey"             . "#A9A9A9")
             ("DarkGreen"            . "#006400")
             ("DarkKhaki"            . "#BDB76B")
             ("DarkMagenta"          . "#8B008B")
             ("DarkOliveGreen"       . "#556B2F")
             ("Darkorange"           . "#FF8C00")
             ("DarkOrchid"           . "#9932CC")
             ("DarkRed"              . "#8B0000")
             ("DarkSalmon"           . "#E9967A")
             ("DarkSeaGreen"         . "#8FBC8F")
             ("DarkSlateBlue"        . "#483D8B")
             ("DarkSlateGray"        . "#2F4F4F")
             ("DarkSlateGrey"        . "#2F4F4F")
             ("DarkTurquoise"        . "#00CED1")
             ("DarkViolet"           . "#9400D3")
             ("DeepPink"             . "#FF1493")
             ("DeepSkyBlue"          . "#00BFFF")
             ("DimGray"              . "#696969")
             ("DimGrey"              . "#696969")
             ("DodgerBlue"           . "#1E90FF")
             ("FireBrick"            . "#B22222")
             ("FloralWhite"          . "#FFFAF0")
             ("ForestGreen"          . "#228B22")
             ("Fuchsia"              . "#FF00FF")
             ("Gainsboro"            . "#DCDCDC")
             ("GhostWhite"           . "#F8F8FF")
             ("Gold"                 . "#FFD700")
             ("GoldenRod"            . "#DAA520")
             ("Gray"                 . "#808080")
             ("Grey"                 . "#808080")
             ("Green"                . "#008000")
             ("GreenYellow"          . "#ADFF2F")
             ("HoneyDew"             . "#F0FFF0")
             ("HotPink"              . "#FF69B4")
             ("IndianRed"            . "#CD5C5C")
             ("Indigo"               . "#4B0082")
             ("Ivory"                . "#FFFFF0")
             ("Khaki"                . "#F0E68C")
             ("Lavender"             . "#E6E6FA")
             ("LavenderBlush"        . "#FFF0F5")
             ("LawnGreen"            . "#7CFC00")
             ("LemonChiffon"         . "#FFFACD")
             ("LightBlue"            . "#ADD8E6")
             ("LightCoral"           . "#F08080")
             ("LightCyan"            . "#E0FFFF")
             ("LightGoldenRodYellow" . "#FAFAD2")
             ("LightGray"            . "#D3D3D3")
             ("LightGrey"            . "#D3D3D3")
             ("LightGreen"           . "#90EE90")
             ("LightPink"            . "#FFB6C1")
             ("LightSalmon"          . "#FFA07A")
             ("LightSeaGreen"        . "#20B2AA")
             ("LightSkyBlue"         . "#87CEFA")
             ("LightSlateGray"       . "#778899")
             ("LightSlateGrey"       . "#778899")
             ("LightSteelBlue"       . "#B0C4DE")
             ("LightYellow"          . "#FFFFE0")
             ("Lime"                 . "#00FF00")
             ("LimeGreen"            . "#32CD32")
             ("Linen"                . "#FAF0E6")
             ("Magenta"              . "#FF00FF")
             ("Maroon"               . "#800000")
             ("MediumAquaMarine"     . "#66CDAA")
             ("MediumBlue"           . "#0000CD")
             ("MediumOrchid"         . "#BA55D3")
             ("MediumPurple"         . "#9370DB")
             ("MediumSeaGreen"       . "#3CB371")
             ("MediumSlateBlue"      . "#7B68EE")
             ("MediumSpringGreen"    . "#00FA9A")
             ("MediumTurquoise"      . "#48D1CC")
             ("MediumVioletRed"      . "#C71585")
             ("MidnightBlue"         . "#191970")
             ("MintCream"            . "#F5FFFA")
             ("MistyRose"            . "#FFE4E1")
             ("Moccasin"             . "#FFE4B5")
             ("NavajoWhite"          . "#FFDEAD")
             ("Navy"                 . "#000080")
             ("OldLace"              . "#FDF5E6")
             ("Olive"                . "#808000")
             ("OliveDrab"            . "#6B8E23")
             ("Orange"               . "#FFA500")
             ("OrangeRed"            . "#FF4500")
             ("Orchid"               . "#DA70D6")
             ("PaleGoldenRod"        . "#EEE8AA")
             ("PaleGreen"            . "#98FB98")
             ("PaleTurquoise"        . "#AFEEEE")
             ("PaleVioletRed"        . "#DB7093")
             ("PapayaWhip"           . "#FFEFD5")
             ("PeachPuff"            . "#FFDAB9")
             ("Peru"                 . "#CD853F")
             ("Pink"                 . "#FFC0CB")
             ("Plum"                 . "#DDA0DD")
             ("PowderBlue"           . "#B0E0E6")
             ("Purple"               . "#800080")
             ("RebeccaPurple"        . "#663399")
             ("Red"                  . "#FF0000")
             ("RosyBrown"            . "#BC8F8F")
             ("RoyalBlue"            . "#4169E1")
             ("SaddleBrown"          . "#8B4513")
             ("Salmon"               . "#FA8072")
             ("SandyBrown"           . "#F4A460")
             ("SeaGreen"             . "#2E8B57")
             ("SeaShell"             . "#FFF5EE")
             ("Sienna"               . "#A0522D")
             ("Silver"               . "#C0C0C0")
             ("SkyBlue"              . "#87CEEB")
             ("SlateBlue"            . "#6A5ACD")
             ("SlateGray"            . "#708090")
             ("SlateGrey"            . "#708090")
             ("Snow"                 . "#FFFAFA")
             ("SpringGreen"          . "#00FF7F")
             ("SteelBlue"            . "#4682B4")
             ("Tan"                  . "#D2B48C")
             ("Teal"                 . "#008080")
             ("Thistle"              . "#D8BFD8")
             ("Tomato"               . "#FF6347")
             ("Turquoise"            . "#40E0D0")
             ("Violet"               . "#EE82EE")
             ("Wheat"                . "#F5DEB3")
             ("White"                . "#FFFFFF")
             ("WhiteSmoke"           . "#F5F5F5")
             ("Yellow"               . "#FFFF00")
             ("YellowGreen"          . "#9ACD32")))
         (web-colors (make-hash-table :test #'equalp :size (length color-pairs))))

    (dolist (color-pair color-pairs web-colors)
      (setf (gethash (car color-pair) web-colors) (cdr color-pair)))))

(defparameter *web-color-scanner*
  (create-scanner
   (concatenate
    'string
    "\\b(?i:"
    (reduce (lambda (a b) (concatenate 'string a "|" b)) (hash-table-keys *web-colors*))
    ")\\b")))

(defun web-color->hex-color (web-color)
  (gethash web-color *web-colors*))

(defun parse-web-color (text)
  (web-color->hex-color (scan-to-strings *web-color-scanner* text)))

(defun normalize-hex-color (hex-color)
  (regex-replace *hex-color-normalize-scanner* hex-color "#\\1\\1\\2\\2\\3\\3"))

(defun parse-hex-color (text)
  (if-let ((values (scan-to-strings *hex-color-scanner* text)))
    (normalize-hex-color values)
    (parse-web-color text)))

(defun hex-color->rgb (hex-color)
  (loop :for start :from 1 :below 7 :by 2
        :for end = (+ start 2)
        :for hex = (subseq hex-color start end)
        :collect (parse-integer hex :radix 16)))

(defun get-photo-id (hex-color)
  (gethash hex-color *cached-photos*))

(defun (setf get-photo-id) (new-value hex-color)
  (setf (gethash hex-color *cached-photos*) new-value))

(defun make-in-memory-photo (hex-color &key (width 100) (height 100))
  (let ((rgb (hex-color->rgb hex-color))
        (png (make-instance 'zpng:pixel-streamed-png
                            :color-type :truecolor
                            :width width
                            :height height)))
    (flex:make-in-memory-input-stream
     (flex:with-output-to-sequence (out :element-type '(unsigned-byte 8))
       (start-png png out)
       (dotimes (_ (* width height))
         (write-pixel rgb png))
       (finish-png png)))))

(defun send-in-memory-photo (bot chat-id photo)
  (let* ((response (http-request
                    (concatenate 'string (endpoint bot) "sendPhoto")
                    :method :post
                    :parameters `(("chat_id" . ,(write-to-string chat-id))
                                  ("photo" . ,photo))
                    :form-data t)))
    (cl-arrows:->>
     (decode-json-from-string (map 'string #'code-char response))
     (assoc 'result)
     cdr
     (assoc 'photo)
     cadr
     (assoc 'file--id))))

(defun send-picture (bot chat-id hex-color)
  (if-let ((photo-id (get-photo-id hex-color)))
    (send-photo bot chat-id photo-id)

    (let* ((photo (make-in-memory-photo hex-color))
           (photo-id (send-in-memory-photo bot chat-id photo)))
      (setf (get-photo-id hex-color) photo-id)
      (save-photos))))

(defun respond-to-update (bot update)
  (let* ((message (access update 'message))
         (text    (access message 'text))
         (chat-id (access message 'chat 'id)))
    (if-let ((hex-color (parse-hex-color text)))
      (send-picture bot chat-id hex-color)
      (send-message bot chat-id "Cant get color"))))

(defparameter *stop-bot* nil)

(defun stop-bot () (setq *stop-bot* t))

(defun start-bot ()
  (setq *stop-bot* nil)
  (loop :with bot = (make-bot *bot-token*)
        :until *stop-bot* :do
          (loop :for update :across (get-updates bot)
                :do (respond-to-update bot update))
          (sleep 2)))

(defun main ()
  (handler-case (start-bot)
    (#+sbcl sb-sys:interactive-interrupt
     #+ccl  ccl:interrupt-signal-condition
     #+clisp system::simple-interrupt-condition
     #+ecl ext:interactive-interrupt
     #+allegro excl:interrupt-signal
     () (progn
          (format *error-output* "Abort.~&")
          (uiop:quit)))))
