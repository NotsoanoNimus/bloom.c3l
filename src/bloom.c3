// Copyright (c) 2026 Zack Puhl <github@xmit.xyz>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the repo's LICENSE file.
module bloom;

import std::collections::allocatedbitset, std::hash, std::math;

fn usz m(usz n, double e) => (usz)math::ceil(n * (-math::ln(e) / math::pow(math::ln(2), 2)));
fn usz k(usz m, usz n) => (usz)math::ceil(((double)m / (double)n) * math::ln(2));

<* Used to hash incoming elements for placement into the Bloom Filter. *>
alias BloomHashFn = fn ulong(char[], ulong);

struct BloomFilter
{
	bool initialized;
	AllocatedBitSet set;
	BloomHashFn hash_fn;
	double false_positive_rate;   // e
	usz bits_required;   // m
	usz upper_bound;   // n
	usz rounds;   // k
}

<*
 @require upper_bound > 0 : "The upper bound must be an integer greater than 0."
 @require false_positive_rate > 0 && false_positive_rate < 1 : "The false-positive rate must be a percentage factor between 0 and 1."
*>
fn BloomFilter create(Allocator allocator, usz upper_bound, double false_positive_rate = 0.01, BloomHashFn hash = &a5hash::hash)
{
	BloomFilter filter = {
		.initialized = true,
		.hash_fn = hash,
		.false_positive_rate = false_positive_rate,
		.bits_required = m(upper_bound, false_positive_rate),
		.upper_bound = upper_bound,
	};
	filter.rounds = k(filter.bits_required, upper_bound);
	filter.set.init(allocator, filter.bits_required);

	return filter;
}

<*
 Release all resources used by the bloom filter and zeroize the struct.

 @param zeroize_filter_contents : "Set to `true` in order to explicitly zeroize the bloom filter in-memory before freeing it."

 @require self.initialized : "The bloom filter must be initialized first."
*>
fn void BloomFilter.free(&self, bool zeroize_filter_contents = false)
{
	if (zeroize_filter_contents) mem::zero_volatile(self.raw());
	self.set.free();
	mem::zero_volatile(@as_char_view(*self));
}

<*
 Provides an approximation of how many elements have been stored in the filter.

 @require self.initialized : "The bloom filter must be initialized first."
*>
fn usz BloomFilter.cardinality(&self)
{
	return (usz)math::ceil(-((double)self.bits_required / (double)self.rounds) * math::ln(1.0d - ((double)self.set.cardinality() / (double)self.bits_required)));
}

macro usz _bitpos(self, char[] element, ulong seed) @local => (usz)(self.hash_fn(element, seed) % self.bits_required);

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

<*
 @require self.initialized : "The bloom filter must be initialized first."
*>
fn char[] BloomFilter.raw(&self) => ((char*)self.set.data.ptr)[:self.set.bits >> 3];
