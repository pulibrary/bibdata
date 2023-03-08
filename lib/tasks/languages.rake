namespace :languages do
  namespace :iso639_5 do
    desc 'refresh the list of collective language codes in this repo from LOC'
    task :refresh_list do
      `wget http://id.loc.gov/vocabulary/iso639-5.tsv -O config/iso639-5.tsv`
      `echo >> config/iso639-5.tsv` # Add a new line to end of file, since LOC's file doesn't have one
    end
  end
end
