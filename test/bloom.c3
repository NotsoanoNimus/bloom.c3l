module test_bloom @test;

import bloom;

fn void init_ok()
{
	BloomFilter f = bloom::create(mem, 100_000_000, 0.000500011);
	// return NOT_IMPLEMENTED~!!;
}