(import ../json)

(var anon-count 0)
(defn test-text [&keys {:text text-data :expected expected-data :name test-name}]
  (default test-name (string "anonymous test #" (++ anon-count)))
  (defn check-expected [expected actual value-name]
    (when (deep-not= expected actual)
      (errorf "Unexpected %s for %s: %p" value-name test-name actual)))
  (def actual-decoded (json/decode text-data))
  (check-expected expected-data actual-decoded "decoded result")
  (def encoded-expected-text (json/encode expected-data))
  (def roundtrip-decoded (json/decode encoded-expected-text))
  (check-expected expected-data roundtrip-decoded "roundtrip result"))

(def example-text ```{
  "empty": [],
  "single": [0],
  "double": [0, 1],
  "triple": [0, 1, 2]
}```)
(def example-data
  {:empty @[]
   :single @[0]
   :double @[0 1]
   :triple @[0 1 2]})

(defn dbg [x]
  (pp x)
  x)

(test-text :text example-text :expected example-data :name "simple")

# (assert (deep= (json/decode example-text) example-data))
# (assert (deep= (json/decode (json/encode example-data)) example-data) "failed to roundtrip")

