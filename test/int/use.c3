module test_bloom_use;

import std::io, std::os;
import bloom;

// ====================================================================
// PARITY WITH create.c3
// TODO: Migrate to a module which can be shared for int tests
//
const AsciiCharset PUNCTUATION = ascii::@create_set(",.?!\";:-`/()[]"); // intentionally excludes apostrophes

fn String canonicalize(String phrase)
{
	String res = phrase.trim().to_lower_tcopy();
	String[] tokens = res.tsplit(" ", skip_empty: true);
	foreach (&t : tokens) *t = t.trim_charset(PUNCTUATION);
	return string::tjoin(tokens, " ");
}

fn void? BloomFilter.check_phrase(&self, String phrase, bool expected = true) => @pool()
{
	if ((expected && !self.contains(canonicalize(phrase))) || (!expected && self.contains(canonicalize(phrase))))
	{
		io::eprintfn(expected ? "MISSING: '%s'" : "UNEXPECTED: '%s'", phrase);
		return NOT_FOUND~;
	}
	io::printfn("---> SUCCESS: phrase '%s' %s.", phrase, expected ? "PROBABLY EXISTS in the set" : "is NOT PRESENT in set");
}
// ====================================================================

fn int main()
{
	io::printfn("~~ IMPORTING SHAKESPEARE FILTER ~~");
	BloomFilter shakespeare_filter = bloom::from(tmem, file::load(tmem, "shakespeare.bloom")!!, 11);
	io::printfn("~~ IMPORTING SHERLOCK FILTER ~~");
	BloomFilter sherlock_filter = bloom::from(tmem, file::load(tmem, "sherlock.bloom")!!, 11);

	io::printfn("~~ TESTING FILTERS ~~");

	shakespeare_filter.check_phrase("parley")!!;
	shakespeare_filter.check_phrase("have not")!!;
	shakespeare_filter.check_phrase("skibbidi toilet", expected: false)!!;
	shakespeare_filter.check_phrase("would have parley")!!;
	shakespeare_filter.check_phrase("would have not parley", expected: false)!!;
	shakespeare_filter.check_phrase("in choosing for yourself")!!;
	shakespeare_filter.check_phrase("being shallow you shall give")!!;
	shakespeare_filter.check_phrase("sister of your loving bride", expected: false)!!;

	sherlock_filter.check_phrase("wolf")!!;
	sherlock_filter.check_phrase("autumn rains the verdure")!!;
	sherlock_filter.check_phrase("C3 has great capabilities", expected: false)!!;

	return 0;
}
