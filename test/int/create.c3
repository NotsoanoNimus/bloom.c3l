module test_bloom_integrations;

import std::io, bloom;

fn void ingest_helper(BloomFilter* into, String contents, usz span) @local => @pool()
{
	io::printfn("-----> Phrase words: %d ...", span);
	String[] tokens = contents.tsplit(" ", skip_empty: true);
	bool uneven = tokens.len % span != 0;
	for (usz i = 0; i < tokens.len - span; i++) into.insert(canonicalize(string::tjoin(tokens[i:span], " ")));
	if (uneven)
	{
		for (usz i = tokens.len % span; i > 0; i--) into.insert(canonicalize(string::tjoin(tokens[^i..], " ")));
	}
}

fn void train_and_save(String filename, String project_name) => @pool()
{
	// NOTE: This particular instance is not very space-efficient. When compared to entries at a word size, or a span of word sizes,
	//       another data structure is likely better. I only realized this well after writing this test, and I don't want to scrap it.
	// By the by, it IS space-efficient if you expand all filtered strings/phrases into its own hash table.
	String name = project_name.to_upper_tcopy();
	io::printfn("~~ INITIALIZING %s FILTER SPACE ~~", name);
	BloomFilter filter = bloom::create(tmem, 10_000_000, 0.000500011);
	io::printfn("-----> Filter will require %d bytes - roughly %.2f MiB - on-disk (when uncompressed).", filter.bits >> 3, (double)(filter.bits >> 3) / 1024d / 1024d);
	io::printfn("~~ INGESTING %s TEXT ~~", name);
	String contents = (String)file::load(mem, filename)!!;
	defer contents.free(mem);
	ingest_helper(&filter, contents, 1);
	ingest_helper(&filter, contents, 2);
	ingest_helper(&filter, contents, 3);
	ingest_helper(&filter, contents, 4);
	ingest_helper(&filter, contents, 5);
	io::printfn("-----> Estimated %s filter entries: %d", project_name.to_lower_tcopy(), filter.cardinality());
	io::printfn("~~ EXPORTING %s ~~", name);
	file::save(string::tformat("%s.bloom", project_name.to_lower_tcopy()), filter.raw())!!;
	io::printn("");
}

fn int main()
{
	if (file::exists("shakespeare.bloom") && file::exists("sherlock.bloom"))
	{
		io::printfn("~~ Filters are already generated. Exiting early. ~~");
		return 0;
	}
	// note: this application should run from the `bloom` project's root directory
	train_and_save("test/int/artifacts/shakespeare.md", "SHAKESPEARE");
	train_and_save("test/int/artifacts/sherlock.md", "SHERLOCK");
	return 0;
}
