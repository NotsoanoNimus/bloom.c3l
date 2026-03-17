module test_bloom_integrations;

import std::io, bloom;

fn int main()
{
	io::printfn("~~ IMPORTING SHAKESPEARE FILTER ~~");
	BloomFilter shakespeare_filter = bloom::from_bytes(tmem, file::load(tmem, "shakespeare.bloom")!!, 11);
	io::printfn("~~ IMPORTING SHERLOCK FILTER ~~");
	BloomFilter sherlock_filter = bloom::from_bytes(tmem, file::load(tmem, "sherlock.bloom")!!, 11);

	io::printfn("~~ TESTING SHAKESPEARE ~~");
	shakespeare_filter.check_phrase("parley")!!;
	shakespeare_filter.check_phrase("have not")!!;
	shakespeare_filter.check_phrase("skibidi toilet", expected: false)!!;
	shakespeare_filter.check_phrase("would have parley")!!;
	shakespeare_filter.check_phrase("would have not parley", expected: false)!!;
	shakespeare_filter.check_phrase("in choosing for yourself")!!;
	shakespeare_filter.check_phrase("being shallow you shall give")!!;
	shakespeare_filter.check_phrase("sister of your loving bride", expected: false)!!;

	io::printfn("~~ TESTING SHERLOCK ~~");
	sherlock_filter.check_phrase("wolf")!!;
	sherlock_filter.check_phrase("autumn rains the verdure")!!;
	sherlock_filter.check_phrase("C3 has great capabilities", expected: false)!!;

	return 0;
}
