module test_bloom_integrations;

import std::io, bloom;

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