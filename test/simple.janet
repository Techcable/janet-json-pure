(import ../json)

# TODO: population used to be a bigint > 32 bits, now it's not
#
# Consider fixing...
(def example-text ```{"name": "John Doe", "age": 31, "number": 1337.37, "address": { "city": "Uppsala", "population": 9223372036854 } }```)
(def example-data {:name "John Doe" :age 31 :number 1337.37 :address { :city "Uppsala" :population 9223372036854 }})

(defn dbg [x]
  (pp x)
  x)

(assert (deep= (json/decode example-text) example-data))
(assert (deep= (json/decode (json/encode example-data)) example-data) "failed to roundtrip")

