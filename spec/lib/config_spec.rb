require 'json'

describe 'From config.rb' do
	before(:all) do

		o='/tmp/sample1.json'
		i=File.expand_path('../../fixtures/sample1.mrx',__FILE__)
		c=File.expand_path('../../../lib/config.rb',__FILE__)
		system "traject -c #{c} #{i} -w Traject::JsonWriter -o #{o}"
	 	@sample1=JSON.parse(IO.read(o))
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
end