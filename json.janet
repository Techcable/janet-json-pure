(def- json-pattern (do
  (defn ascii-split [str] (map string/from-bytes (string/bytes str)))
  (defn janet-builtin-escape [c] (parse (string/format ``"\%s"`` c)))
  (def- simple-escape-table (merge {
    "b" "\x08"
    "/" "/"
    # Parse builtin to janet
  } (struct ;(mapcat (fn [c] [c (janet-builtin-escape c)]) (ascii-split ``"\nrtf``)))))
  (def- literal-table {
    "true" true
    "false" false
    "null" nil})
  (peg/compile
    # Very closely mirrors json.org grammar (right side)
    #
    # Main differences is capturing
    ~{:main (* :element -1)
      :element (* :s* :value :s*)
      :value (+ :object
                :array
                :string
                :number
                (/ (+ "true" "false" "null") ,literal-table))
      :object (/ (* "{" (+ :members) "}") ,struct)
      :members (+ (* (some (* :member ",")) :member) :member)
      :member (* :s* (/ :string ,keyword) :s* ":" :element)
      :elements (+ (* (some (* :element ",")) :element))
      :array (group (* "[" (+ :elements :s*) "]"))
      # After validating, we can trust builtin parse to return a floating point number
      #
      # TODO: bigint?
      :number (/ (capture (* :integer :fraction :exponent)) ,parse)
      :exponent (? (* (set "eE") (? (set "+-")) :d*))
      :fraction (? (* "." :d*))
      :integer (* (? "-") (+ "0" (* (range "19") :d*)))
      :string (* "\"" (accumulate (any :character)) "\"")
      # Forbidden chars: set(range('\u0000', '\u001F')) | {'"', '\\'}
      # Aside from these, we permit the entire Basic Multilingual Plane (UCS2)
      #
      # Potential: opt, combine range, and invert
      :character (+ (capture (if-not (+ (range "\x00\x1F") "\"" "\\") 1)) :escapedChar)
      :escapedChar (+ (* "\\" (/ (capture (set ``"\/bfnrt``)) ,simple-escape-table)) :unicodeEscape)
      # NOTE: Use builtin parse for unicode escapes
      :unicodeEscape (/ (capture (* "u" (repeat 4 (+ :h :H)))) ,parse)})))

(defn decode [text]
  (def arr (peg/match json-pattern text))
  (if (nil? arr) (error "Invalid json!") (first arr)))
