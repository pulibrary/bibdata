def stub_request_bibs
  stub_request(:get, /.*\.exlibrisgroup\.com\/almaws\/v1\/bibs/).
        to_return(:status => 200,
                  :headers => { "Content-Type" => "application/json" },
                  :body => File.new('spec/fixtures/alma_mms_id_99939650000541.json'))
end