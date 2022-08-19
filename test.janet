(import ./json)

(pp (json/decode "{\"name\": \"John Doe\", \"age\": 31, \"number\": 1337.37, \"address\": { \"city\": \"Uppsala\", \"population\": 9223372036854775807 } }"))
