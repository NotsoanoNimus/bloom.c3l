# bloom.c3l - Universal Bloom Filters &amp; Extensions for the C3 Language

A [Bloom Filter](https://en.wikipedia.org/wiki/Bloom_filter) is a universal data structure which uses hashing and bitsets to provide space-efficient, constant-time insertion and lookup.

The key property of these filters is that set membership is evaluated as `definitely not in set` or `maybe in set`. For set lookups - e.g., some certificate's membership in a very long list of revoked fingerprints - getting a negative result can immediately and quickly stop any further operations without traversing the entire set.

Another unique property is that lookups/insertions remain constant-time regardless of how many elements are already in the set.


## Idiosyncrasies
- From a usability perspective, with most filter sizes, bloom filters are almost always workable in-memory. Therefore, they can be flushed to long-term storage if and whenever _the developer_ chooses, not by the library itself in order to preserve some kind of interim state information.
- Given an `n` (number of stored elements) of around 100 million, an assumption of about 10 bits allocated per expected `n` would result in a Bloom filter of only about `120 MiB` of data! Pretty great for input elements of _any given size_; when you consider even a `ulong` element type, this is a significant space-savings.
- You cannot remove elements from an ordinary bloom filter, as the bits set to zero for one element may be shared by other elements in the set.
- The hashing algorithm used by this library defaults to the C3 standard library's `a5hash` implementation, but that can be overridden upon filter creation. The signature of the desired hash function _must_ match `fn ulong(char[] element, ulong hash_seed)` - AKA, the `BloomHashFn` type.


# Usage
There are some important module-level functions exposed:
- `create` - create a new filter instance and allocate necessary space
- `from_bytes` - import a raw bloom filter from a byte array

The core `BloomFilter` structure provides the following methods:
- `copy` - spawn an in-memory copy of the filter and its meta-data
- `free` - deallocate and zeroize a filter
- `cardinality` - return an approximation of how many elements are stored by the filter
- `raw` - return a byte-array view of the filter's raw data
- `insert` - add a new element to the filter
- `contains` - query whether the element likely exists in the set

Any supplemental bloom filter types - e.g., counting bloom filters - will have similar methods exposed.

### Making a filter
Creation of a **new** filter expects foreknowledge of:
- a maximum, upper-bound elements value, `n`, as a `usz` (integer)
- a target false-positive rate as a non-zero `double` value, 0 < `e` < 1
- the dataset's hash function, if not using the default `std::hash::a5hash`

Use the `bloom::create` function to allocate and return a new filter that's ready to populate.

For existing filters, use the `bloom::import` function, which expects foreknowledge of:
- the dataset's hash function, if it doesn't use the default `std::hash::a5hash`
- how many rounds of that hash to apply on each `insert` or `contains`

The ability to import filters from a byte array allows each bloom filter to be saved in long-term storage (using the `raw` method) after it's created. The saved filter can then be reused later for queries and/or it can be further amended by `insert` calls.

### Inserting elements
**Any linear, byte-array view** of some data, structured or not, can be inserted into a bloom filter; it is not a "typed" filter.

Simply determine the best manner to view your data as bytes and insert it into the filter with the `insert` method call.

### Lookups
Checking membership in the set with `contains` is a short-circuited version of the `insert` method. A byte-array view of an element is provided and each bit position resulting from the hash function computation is checked.

If all bits resulting from the input element are set, then the element is _likely_ already in the set. If any are unset, the element is _absolutely not_ in the set.

### Approximating the stored element count
The `cardinality` member function returns an _approximation_ of how many unique elements are present in the set. The computation here is derived from [this text](https://en.wikipedia.org/wiki/Bloom_filter#Approximating_the_number_of_items_in_a_Bloom_filter).

