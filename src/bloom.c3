// Copyright (c) 2026 Zack Puhl <github@xmit.xyz>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the repo's LICENSE file.
module bloom;

import std::collections::allocatedbitset, std::hash, std::math;

fn usz target_bitsize(usz n, double e)
{
	usz m = (usz)math::ceil(n * (-math::ln(e) / math::pow(math::ln(2), 2)));
	if (m % 8 != 0) m += 8 - (m % 8);   // round up to the nearest byte boundary
	assert (m % 8 == 0);
	return m;
}
fn usz target_hash_funcs(usz m, usz n) => (usz)math::ceil(((double)m / (double)n) * math::ln(2));

<* Used to hash incoming elements for placement into the Bloom Filter. *>
alias BloomHashFn = fn ulong(char[], ulong);

struct BloomFilter
{
	bool initialized;   // acts as a "dirty" flag, indicating the filter was properly init'd
	AllocatedBitSet set;
	BloomHashFn hash_fn;
	usz bits;   // m
	usz rounds;   // k
}

<*
 @require upper_bound > 0 : "The upper bound must be an integer greater than 0."
 @require false_positive_rate > 0 && false_positive_rate < 1 : "The false-positive rate must be a percentage factor between 0 and 1."
*>
macro BloomFilter create(Allocator allocator, usz upper_bound, double false_positive_rate = 0.01, BloomHashFn hash = &a5hash::hash)
	=> _create_impl(allocator, upper_bound, false_positive_rate, hash);

<*
 @require upper_bound > 0 : "The upper bound must be an integer greater than 0."
 @require false_positive_rate > 0 && false_positive_rate < 1 : "The false-positive rate must be a percentage factor between 0 and 1."
*>
fn BloomFilter _create_impl(Allocator allocator, usz upper_bound, double false_positive_rate = 0.01, BloomHashFn hash = &a5hash::hash, usz bucket_width = 1) @private
{
	usz bitsize = target_bitsize(upper_bound, false_positive_rate) * bucket_width;
	BloomFilter filter = {
		.initialized = true,
		.hash_fn = hash,
		.bits = bitsize,
		.rounds = target_hash_funcs(bitsize, upper_bound)
	};
	filter.set.init(allocator, filter.bits);
	return filter;
}

<*
 Import a bloom filter from a raw array of bytes. This requires foreknowledge of the right hash
 function and round count which was used to create the incoming filter data.

 @require filter_raw.len > 0 : "You cannot create a bloom filter from an empty byte array. Use `create` instead."
 @require hash_rounds > 0 : "All bloom filters must use at least 1 hash round."
 *>
fn BloomFilter from_bytes(Allocator allocator, char[] filter_raw, usz hash_rounds, BloomHashFn hash = &a5hash::hash)
{
	BloomFilter filter = {
		.initialized = true,
		.hash_fn = hash,
		.bits = filter_raw.len << 3,
		.rounds = hash_rounds,
	};
	filter.set.init(allocator, filter.bits);
	filter.raw()[:filter_raw.len] = filter_raw[..];   // copy into bytes allocated by the bitset
	return filter;
}

<*
 Create a copy of a bloom filter in-memory and return the new structure.

 @param [&inout] allocator : "The allocator to use when copying the filter."
*>
fn BloomFilter BloomFilter.copy(&self, Allocator allocator) => {
	...*self,
	.set = self.set.copy(allocator),
};

<*
 Release all resources used by the bloom filter and zeroize the struct.

 @param zeroize_filter_contents : "Set to `true` in order to explicitly zeroize the bloom filter in-memory before freeing it."

 @require self.initialized : "The bloom filter must be initialized first."
*>
fn void BloomFilter.free(&self, bool zeroize_filter_contents = false)
{
	if (zeroize_filter_contents) mem::zero_volatile(self.raw());
	if (self.initialized) self.set.free();
	mem::zero_volatile(@as_char_view(*self));
}

<*
 Provides an approximation of how many elements have been stored in the filter.

 @require self.initialized : "The bloom filter must be initialized first."
*>
fn usz BloomFilter.cardinality(&self)
{
	return (usz)math::ceil(-((double)self.bits / (double)self.rounds) * math::ln(1.0d - ((double)self.set.cardinality() / (double)self.bits)));
}

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn char[] BloomFilter.raw(&self) => ((char*)self.set.data.ptr)[:self.set.bits >> 3];

macro usz _bitpos(self, char[] element, ulong seed) @local => (usz)(self.hash_fn(element, seed) % self.bits);

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn void BloomFilter.insert(&self, char[] element)
{
	for (usz i = 0; i < self.rounds; i++) self.set.set(_bitpos(self, element, (ulong)i));
}

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn bool BloomFilter.contains(&self, char[] element)
{
	for (usz i = 0; i < self.rounds; i++)
	{
		if (!self.set[_bitpos(self, element, (ulong)i)]) return false;
	}
	return true;
}
