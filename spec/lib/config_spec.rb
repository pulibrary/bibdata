require 'json'

describe 'From config.rb' do
	before(:all) do

		def trajectify(fixture_name) 
			o='/tmp/tmp.json'
			i=File.expand_path("../../fixtures/#{fixture_name}.mrx",__FILE__)
			c=File.expand_path('../../../lib/traject_config.rb',__FILE__)
			system "traject -c #{c} #{i} -w Traject::JsonWriter -o #{o}"
			JSON.parse(IO.read(o))
		end			
	  	@sample1=trajectify('sample1')
	  	@sample2=trajectify('sample2')
	  	@sample3=trajectify('sample3')

	end

	describe 'the id field' do
		it 'has exactly 1 value' do
			expect(@sample1['id'].length).to eq 1
		end
	end
	describe 'the title_sort field' do
		it 'does not have initial articles' do
			expect(@sample1['title_sort'][0].start_with?('advanced concepts')).to be_truthy
		end
	end
	describe 'the author_display field' do
		it 'takes from the 100 field' do
			expect(@sample1['author_display'][0]).to eq 'Singh, Digvijai, 1934-'
		end
		it 'shows only 100 field' do
			expect(@sample2['author_display'][0]).to eq 'White, Michael M.'
		end
		it 'shows 110 field' do
			expect(@sample3['author_display'][0]).to eq 'World Data Center A for Glaciology'
		end					
	end
end
