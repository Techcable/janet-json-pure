# A tiny JSON library, written entirely in janet (and kept very small).
#
# Becuase it is so small and simple (<150 lines), it is easy to copy this file directly into your project.
# In fact, directly copying this file is the prefered mode of installation.
#
# The license is effectively public-domain (dual CC0 & MIT),
# so no copyright disclaimer is needed (even for proprietary binaries).
#
# Source code & issue tracker: https://github.com/Techcable/plainlib
#
# VERSION: 0.1.0
#
# CHANGELOG:
#
# NEXT:
#
# 0.1.0: - Initial release


(defn- ascii-split [str] (map string/from-bytes (string/bytes str)))
(defn- janet-builtin-escape [c] (parse (string/format ``"\%s"`` c)))
(def- simple-escape-table "The 'simple' json escapes (non unicode)" (struct
  "b" "\x08"
  "/" "/"
  # Use Janet's parse builtin
  ;(mapcat (fn [c] [c (janet-builtin-escape c)]) (ascii-split ``"\nrtf``))))
(def- inverse-escape-table (from-pairs (map reverse (pairs simple-escape-table))))

(def- json-pattern (do
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
      :elements (+ (* (some (* :element ",")) :element) :element)
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

# Defined later
(var- default-type-map nil)

# TODO: Should use encoder table and one big buffer instead of recursive concat
#
# Maybe dynamic bindings could help with overriding type-map?
(defn encode "Encode the specified value as json text" [value]
  (if-let [encoder (get default-type-map (type value))]
    (encoder value)
    (errorf "Unable to encode type %t: %j" value value)))


(defn decode
  ``Decodes the specified json string into a janet value.

  Relies on Janet's builtin peg engine for all internal parse work.``
  [text]
  (def arr (peg/match json-pattern text))
  (if (nil? arr) (error "Invalid json!") (first arr)))

(defn- encode-string [txt]
  # TODO: Only handles ascii chars
  # TODO: Speedup and compact
  (def buf @"\"")
  (defn- escape-char [c] (string "\\" (if-let [escaped (get inverse-escape-table c)] c (string/format "u%04X" ;(string/bytes c)))))
  (def forbidden-ascii-chars (comptime (string ``\"`` (string/from-bytes ;(range 0 32)))))
  (loop [b :in txt]
    (assert (< b 128) (errorf "Can only handle ASCII chars (Janet stdlib has no UTF8): %q" b))
    (def s (string/from-bytes b))
    (def escaped (if (string/check-set forbidden-ascii-chars s) (escape-char s) s))
    (buffer/push buf escaped))
  (buffer/push buf "\"")
  buf) 

(defn- encode-seq [s] (string "[" (string/join (map  s) ",") "]"))

(defn- encode-map [m] (string "{" (string/join (seq [[key val] :pairs m] (string/format "%s: %s" (encode key) (encode val))) ",") "}"))

(set default-type-map
  {:nil (fn [_] "null")
   :boolean string
   :number string
   :keyword encode-string
   :symbol encode-string
   :string encode-string
   :buffer encode-string # NOTE: Change default to interpret as bytes?
   :array encode-seq
   :table encode-map
   :struct encode-map})

