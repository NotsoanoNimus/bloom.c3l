
// Copyright (c) 2026 Zack Puhl <github@xmit.xyz>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the repo's LICENSE file.
module std::collections::allocatedbitset;

const BITS = bitsizeof(uint);

struct AllocatedBitSet
{
	Allocator allocator;
	bool initialized;
	uint[] data;
	usz bits;
}

fn void AllocatedBitSet.init(&self, Allocator allocator, usz bits)
{
	usz size = (bits + BITS - 1) / BITS;
	uint[] data = allocator::alloc_array(allocator, uint, size)[:size];
	*self = {
		.allocator = allocator,
		.initialized = true,
		.data = data,
		.bits = size,
	};
}

fn void AllocatedBitSet.free(&self)
{
	allocator::free(self.allocator, self.data.ptr);
	mem::zero_volatile(@as_char_view(*self));
}

<*
 @return "The number of bits set"
*>
fn usz AllocatedBitSet.cardinality(&self)
{
	usz n;
	foreach (x : self.data)
	{
		n += x.popcount();
	}
	return n;
}

<*
 Set a bit in the Allocatedbitset.

 @param i : "The index to set"

 @require i < self.bits : "Index was out of range"
*>
fn void AllocatedBitSet.set(&self, usz i)
{
	usz q = i / BITS;
	usz r = i % BITS;
	self.data[q] |= 1 << r;
}

<*
 Perform xor over all bits, mutating itself

 @param set : "The bit set to xor with"
 @return "The resulting bit set"
*>
macro AllocatedBitSet AllocatedBitSet.xor_self(&self, AllocatedBitSet set) @operator(^=)
{
	foreach (i, &x : self.data) *x ^= set.data[i];
	return *self;
}

<*
 Perform xor over all bits, returning a new bit set.

 @param set : "The bit set to xor with"
 @return "The resulting bit set"
*>
fn AllocatedBitSet AllocatedBitSet.xor(&self, AllocatedBitSet set) @operator(^)
{
	AllocatedBitSet new_set @noinit;
	foreach (i, x : self.data) new_set.data[i] = x ^ set.data[i];
	return new_set;
}

<*
 Perform or over all bits, returning a new bit set.

 @param set : "The bit set to xor with"
 @return "The resulting bit set"
*>
fn AllocatedBitSet AllocatedBitSet.or(&self, AllocatedBitSet set) @operator(|)
{
	AllocatedBitSet new_set @noinit;
	foreach (i, x : self.data) new_set.data[i] = x | set.data[i];
	return new_set;
}

<*
 Perform or over all bits, mutating itself

 @param set : "The bit set to xor with"
 @return "The resulting bit set"
*>
macro AllocatedBitSet AllocatedBitSet.or_self(&self, AllocatedBitSet set) @operator(|=)
{
	foreach (i, &x : self.data) *x |= set.data[i];
	return *self;
}

<*
 Perform & over all bits, returning a new bit set.

 @param set : "The bit set to xor with"
 @return "The resulting bit set"
*>
fn AllocatedBitSet AllocatedBitSet.and(&self, AllocatedBitSet set) @operator(&)
{
	AllocatedBitSet new_set @noinit;
	foreach (i, x : self.data) new_set.data[i] = x & set.data[i];
	return new_set;
}

<*
 Perform & over all bits, mutating itself.

 @param set : "The bit set to xor with"
 @return "The resulting bit set"
*>
macro AllocatedBitSet AllocatedBitSet.and_self(&self, AllocatedBitSet set) @operator(&=)
{
	foreach (i, &x : self.data) *x &= set.data[i];
	return *self;
}

<*
 Unset (clear) a bit in the Allocatedbitset.

 @param i : "The index to set"

 @require i < self.bits : "Index was out of range"
*>
fn void AllocatedBitSet.unset(&self, usz i)
{
	usz q = i / BITS;
	usz r = i % BITS;
	self.data[q] &= ~(1 << r);
}

<*
 Get a particular bit in the Allocatedbitset

 @param i : "The index of the bit"

 @require i < self.bits : "Index was out of range"
 @pure
*>
fn bool AllocatedBitSet.get(&self, usz i) @operator([]) @inline
{
	usz q = i / BITS;
	usz r = i % BITS;
	return self.data[q] & (1 << r) != 0;
}

<*
 Return the number of bits.

 @pure
*>
fn usz AllocatedBitSet.len(&self) @operator(len) @inline => self.data.len;

<*
 Change a particular bit in the Allocatedbitset

 @param i : "The index of the bit"
 @param value : "The value to set the bit to"

 @require i < self.bits : "Index was out of range"
*>
fn void AllocatedBitSet.set_bool(&self, usz i, bool value) @operator([]=) @inline
{
	if (value) return self.set(i);
	self.unset(i);
}
