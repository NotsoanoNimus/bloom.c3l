module test_bloom_gen;

import std::io, std::os;
import bloom;

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
	io::printfn("---> SUCCESS: phrase '%s' %s.", phrase, expected ? "MAY EXIST in the set" : "is NOT PRESENT in set");
}

fn void ingest_helper(BloomFilter* into, String contents, usz span) @local => @pool()
{
	String[] tokens = contents.tsplit(" ", skip_empty: true);
	bool uneven = tokens.len % span != 0;
	for (usz i = 0; i < tokens.len - span; i++) into.insert(canonicalize(string::tjoin(tokens[i:span], " ")));
	if (uneven)
	{
		for (usz i = tokens.len % span; i > 0; i--) into.insert(canonicalize(string::tjoin(tokens[^i..], " ")));
	}
}

fn void ingest_words(BloomFilter* into, String filename)
{
	// note: this application should run from the `bloom` project's root directory
	String contents = (String)file::load(mem, filename)!!;
	defer contents.free(mem);
	ingest_helper(into, contents, 1);
	ingest_helper(into, contents, 2);
	ingest_helper(into, contents, 3);
	ingest_helper(into, contents, 4);
	ingest_helper(into, contents, 5);
}

fn int main() => @pool()
{
	io::printfn("~~ INITIALIZING SHAKESPEARE FILTER SPACE ~~");
	BloomFilter shakespeare_filter = bloom::create(tmem, 10_000_000, 0.000500011);
	io::printfn("~~ INGESTING SHAKESPEARE TEXT ~~");
	ingest_words(&shakespeare_filter, "test/int/artifacts/shakespeare.md");
	io::printfn("~~ BEGIN QUERIES ~~");
	io::printfn("Estimated Shakespeare filter entries: %d", shakespeare_filter.cardinality());

	shakespeare_filter.check_phrase("parley")!!;
	shakespeare_filter.check_phrase("have not")!!;
	shakespeare_filter.check_phrase("skibbidi toilet", expected: false)!!;
	shakespeare_filter.check_phrase("would have parley")!!;
	shakespeare_filter.check_phrase("would have not parley", expected: false)!!;
	shakespeare_filter.check_phrase("in choosing for yourself")!!;
	shakespeare_filter.check_phrase("being shallow you shall give")!!;
	shakespeare_filter.check_phrase("sister of your loving bride", expected: false)!!;

	io::printfn("~~ INITIALIZING SHERLOCK FILTER SPACE ~~");
	BloomFilter sherlock_filter = bloom::create(tmem, 10_000_000, 0.000500011);
	io::printfn("~~ INGESTING SHERLOCK TEXT ~~");
	ingest_words(&sherlock_filter, "test/int/artifacts/sherlock.md");
	io::printfn("~~ BEGIN QUERIES ~~");
	io::printfn("Estimated Sherlock filter entries: %d", sherlock_filter.cardinality());

	sherlock_filter.check_phrase("wolf")!!;
	sherlock_filter.check_phrase("autumn rains the verdure")!!;
	sherlock_filter.check_phrase("C3 has great capabilities", expected: false)!!;

	io::printfn("~~ EXPORTING FILTERS ~~");
	return 0;
}
