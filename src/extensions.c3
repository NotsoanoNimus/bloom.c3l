// Copyright (c) 2026 Zack Puhl <github@xmit.xyz>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the repo's LICENSE file.
//
// TODO: THIS MODULE IS INCOMPLETE
module bloom;

import std::math;

faultdef
	BUCKET_WOULD_OVERFLOW;   // inserting the given element would overflow the bucket's counter

struct CountingBloomFilter
{
	inline BloomFilter b;
	usz bits_per_bucket;
}

<*
 @require upper_bound > 0 : "The upper bound must be an integer greater than 0."
 @require false_positive_rate > 0 && false_positive_rate < 1 : "The false-positive rate must be a percentage factor between 0 and 1."
 @require bits_per_bucket > 1 && bits_per_bucket <= 32
 	: "Bits per bucket must be greater than 1 and less than or equal to 32. If you want 1-bit-sized buckets, use an ordinary `BloomFilter`."
*>
fn CountingBloomFilter create_counting(Allocator allocator, usz bits_per_bucket, usz upper_bound, double false_positive_rate = 0.01, BloomHashFn hash = &a5hash::hash)
{
	CountingBloomFilter filter = { .bits_per_bucket = bits_per_bucket };
	filter.b = bloom::_create_impl(allocator, upper_bound, false_positive_rate, hash, bits_per_bucket);
	return filter;
}

<*
 @require filter_raw.len > 0 : "You cannot create a bloom filter from an empty byte array. Use `create` instead."
 @require hash_rounds > 0 : "All bloom filters must use at least 1 hash round."
 @require bits_per_bucket > 1 && bits_per_bucket <= 32
 	: "Bits per bucket must be greater than 1 and less than or equal to 32. If you want 1-bit-sized buckets, use an ordinary `BloomFilter`."
*>
fn CountingBloomFilter from_bytes_counting(Allocator allocator, char[] filter_raw, usz hash_rounds, usz bits_per_bucket, BloomHashFn hash = &a5hash::hash)
{
	CountingBloomFilter filter = { .bits_per_bucket = bits_per_bucket };
	filter.b = bloom::from_bytes(allocator, filter_raw, hash_rounds, hash);
	return filter;
}

<*
 Create a copy of a bloom filter in-memory and return the new structure.

 @param [&inout] allocator : "The allocator to use when copying the filter."
*>
fn CountingBloomFilter CountingBloomFilter.copy(&self, Allocator allocator) => {
	...*self,
	.set = self.set.copy(allocator),
};

<*
 Release all resources used by the bloom filter and zeroize the struct.

 @param zeroize_filter_contents : "Set to `true` in order to explicitly zeroize the bloom filter in-memory before freeing it."

 @require self.initialized : "The bloom filter must be initialized first."
*>
fn void CountingBloomFilter.free(&self, bool zeroize_filter_contents = false)
{
	if (zeroize_filter_contents) mem::zero_volatile(self.raw());
	if (self.initialized) self.set.free();
	mem::zero_volatile(@as_char_view(*self));
}

<*
 Provides an approximation of how many elements have been stored in the filter.

 @require self.initialized : "The bloom filter must be initialized first."
*>
fn usz CountingBloomFilter.cardinality(&self)
{
	double bit_factor = (double)(self.bits / self.bits_per_bucket);
	return (usz)math::ceil(-(bit_factor / (double)self.rounds) * math::ln(1.0d - ((double)self.set.cardinality() / bit_factor)));
}

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn char[] CountingBloomFilter.raw(&self) => ((char*)self.set.data.ptr)[:self.set.bits >> 3];

macro usz _bitpos(self, char[] element, ulong seed) @local => (usz)(self.hash_fn(element, seed) % self.bits);

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn void CountingBloomFilter.insert(&self, char[] element)
{
	for (usz i = 0; i < self.rounds; i++) self.set.set(_bitpos(self, element, (ulong)i));
}

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn bool CountingBloomFilter.contains(&self, char[] element)
{
	for (usz i = 0; i < self.rounds; i++)
	{
		if (!self.set[_bitpos(self, element, (ulong)i)]) return false;
	}
	return true;
}
