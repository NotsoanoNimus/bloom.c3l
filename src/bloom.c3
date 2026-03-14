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
	Allocator allocator;
	AllocatedBitSet set;
	BloomHashFn hash_fn;
	double false_positive_rate;   // e
	usz bits_required;   // m
	usz upper_bound;   // n
	usz rounds;   // k
}

import std::io;
<*
 @require upper_bound > 0 : "The upper bound must be an integer greater than 0."
 @require false_positive_rate > 0 && false_positive_rate < 1 : "The false-positive rate must be a percentage factor between 0 and 1."
*>
fn BloomFilter create(Allocator allocator, usz upper_bound, double false_positive_rate = 0.01, BloomHashFn hash = &a5hash::hash)
{
	BloomFilter filter = {
		.allocator = allocator,
		.hash_fn = hash,
		.false_positive_rate = false_positive_rate,
		.bits_required = m(upper_bound, false_positive_rate),
		.upper_bound = upper_bound,
	};
	filter.rounds = k(filter.bits_required, upper_bound);
	filter.set.init(allocator, filter.bits_required);
io::printfn("USING BITS COUNT: %d  ///  K of %d  ///  lenof %d", filter.bits_required, filter.rounds, filter.set.data.len);

	return filter;
}

fn usz BloomFilter.cardinality(&self)
{
	return (usz)math::ceil(-((double)self.bits_required / (double)self.rounds) * math::ln(1.0d - ((double)self.set.cardinality() / (double)self.bits_required)));
}
