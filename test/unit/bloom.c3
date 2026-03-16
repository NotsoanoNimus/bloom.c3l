module test_bloom @test;

import bloom;

fn void create_ok()
{
	BloomFilter f = bloom::create(tmem, 100_000_000, 0.000500011);
	test::eq(f.rounds, 11);
	test::@check(f.set.data.len > 30_000);
}