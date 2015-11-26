require 'spec_helper'
require './lib/graph_gist_tools'

RSpec.describe GraphGistTools do
  use_vcr_cassette 'graph_gist_tools', record: :new_episodes

  describe '.raw_url_for' do
    subject { GraphGistTools.raw_url_for(url) }

    # GitHub Gists
    let_context url: 'https://gist.github.com/galliva/ca811daa580aee95bd07' do
      it { should eq 'https://gist.githubusercontent.com/galliva/ca811daa580aee95bd07/raw/aa11f84ec7cd02beeefd0bf892602cbf1ed09797/NoSQLGist' }
    end
    let_context url: 'https://gist.github.com/ca811daa580aee95bd07' do
      it { should eq 'https://gist.githubusercontent.com/galliva/ca811daa580aee95bd07/raw/aa11f84ec7cd02beeefd0bf892602cbf1ed09797/NoSQLGist' }
    end
    let_context url: 'https://gist.github.com/roquec/8176106' do
      it { should eq 'https://gist.githubusercontent.com/roquec/8176106/raw/872d8051788c08eeacb2e52c349e9c6bdf8e4803/medicine.adoc' }
    end
    let_context url: 'https://gist.github.com/roquec/8176106#with-anchor' do
      it { should eq 'https://gist.githubusercontent.com/roquec/8176106/raw/872d8051788c08eeacb2e52c349e9c6bdf8e4803/medicine.adoc' }
    end

    # Via gist.neo4j.org
    let_context url: 'http://gist.neo4j.org/?8176106' do
      it { should eq 'https://gist.githubusercontent.com/roquec/8176106/raw/872d8051788c08eeacb2e52c349e9c6bdf8e4803/medicine.adoc' }
    end
    let_context url: 'http://gist.neo4j.org/?8176106#with-anchor' do
      it { should eq 'https://gist.githubusercontent.com/roquec/8176106/raw/872d8051788c08eeacb2e52c349e9c6bdf8e4803/medicine.adoc' }
    end
    let_context url: 'https://gist.neo4j.org/?github-kbastani/gists//meta/TimeScaleEventMetaModel.adoc' do
      it { should eq 'https://raw.githubusercontent.com/kbastani/gists/master/meta/TimeScaleEventMetaModel.adoc' }
    end

    let_context url: 'https://gist.github.com/patbaumgartner/8139605' do
      it { should eq 'something' }
    end

    # Github repos
    let_context url: 'http://github.com/neo4j-examples/graphgists/blob/master/fraud/bank-fraud-detection.adoc' do
      it { should eq 'https://raw.githubusercontent.com/neo4j-examples/graphgists/master/fraud/bank-fraud-detection.adoc' }
    end

    let_context url: 'https://github.com/kvangundy/Slashco/blob/master/slashco.adoc' do
      it { should eq 'https://raw.githubusercontent.com/kvangundy/Slashco/master/slashco.adoc' }
    end

    describe 'Dropbox' do
      let_context url: 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=0' do
        it { should eq 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=1' }
      end

      let_context url: 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt' do
        it { should eq 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=1' }
      end

      let_context url: 'https://dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=0' do
        it { should eq 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=1' }
      end

      let_context url: 'http://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=0' do
        it { should eq 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=1' }
      end

      let_context url: 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=1' do
        it { should eq 'https://www.dropbox.com/s/81fka14d5hyg378/gistfile1.txt?dl=1' }
      end
    end

    describe 'pastebin' do
      let_context url: 'http://pastebin.com/AFmNzecE' do
        it { should eq 'http://pastebin.com/raw.php?i=AFmNzecE' }
      end

      let_context url: 'https://pastebin.com/AFmNzecE' do
        it { should eq 'http://pastebin.com/raw.php?i=AFmNzecE' }
      end

      let_context url: 'https://www.pastebin.com/AFmNzecE' do
        it { should eq 'http://pastebin.com/raw.php?i=AFmNzecE' }
      end
    end

    describe 'etherpad' do
      let_context url: 'https://public.etherpad-mozilla.org/p/aouoeuoeu' do
        it { should eq 'https://public.etherpad-mozilla.org/p/aouoeuoeu/export/txt' }
      end

      let_context url: 'http://beta.etherpad.org/p/IudqLHvuRj' do
        it { should eq 'http://beta.etherpad.org/p/IudqLHvuRj/export/txt' }
      end
    end

    describe 'Google docs' do
      let_context url: 'https://docs.google.com/document/u/0/export?format=txt&id=1mWWQ8bp6-q_D4SOpcfhmQ4fKaNsfQDtx5zxTu3D2uIw&token=AC4w5VhoYYXF6XPJLJfjfIufyeHlai6D-g%3A1447325752412' do
        it { should eq 'https://docs.google.com/document/u/0/export?format=txt&id=1mWWQ8bp6-q_D4SOpcfhmQ4fKaNsfQDtx5zxTu3D2uIw&token=AC4w5VhoYYXF6XPJLJfjfIufyeHlai6D-g%3A1447325752412' }
      end

      let_context url: 'https://docs.google.com/document/d/1mWWQ8bp6-q_D4SOpcfhmQ4fKaNsfQDtx5zxTu3D2uIw/edit' do
        it { should eq 'https://docs.google.com/document/u/0/export?format=txt&id=1mWWQ8bp6-q_D4SOpcfhmQ4fKaNsfQDtx5zxTu3D2uIw' }
      end

      let_context url: 'https://docs.google.com/document/d/1mWWQ8bp6-q_D4SOpcfhmQ4fKaNsfQDtx5zxTu3D2uIw' do
        it { should eq 'https://docs.google.com/document/u/0/export?format=txt&id=1mWWQ8bp6-q_D4SOpcfhmQ4fKaNsfQDtx5zxTu3D2uIw' }
      end
    end

    describe 'non-text responses' do
      let_context url: 'https://gricker.files.wordpress.com/2015/02/graph.png' do
        it { should be_nil }
      end
    end
  end

  # This is the method which converts the special GraphGist URL syntax to URLs
  describe '.raw_url_for_graphgist_id' do
    subject { GraphGistTools.raw_url_for_graphgist_id(id) }
    describe 'GitHub gists' do
      let_context id: '8176106' do
        it { should eq 'https://gist.githubusercontent.com/roquec/8176106/raw/872d8051788c08eeacb2e52c349e9c6bdf8e4803/medicine.adoc' }
      end
      let_context id: '6009066' do
        it { should eq 'https://gist.githubusercontent.com/peterneubauer/6009066/raw/b0dd549f6299b4a5dcc9e32982996f33b012c415/T-Graph.adoc' }
      end
    end

    describe 'GitHub files' do
      let_context id: 'github-kbastani/gists//meta/TimeScaleEventMetaModel.adoc' do
        it { should eq 'https://raw.githubusercontent.com/kbastani/gists/master/meta/TimeScaleEventMetaModel.adoc' }
      end
      let_context id: 'github-whatSocks/jobSNV//socialNetworks.adoc' do
        it { should eq 'https://raw.githubusercontent.com/whatSocks/jobSNV/master/socialNetworks.adoc' }
      end
      # Encoded
      let_context id: 'github-neo4j-contrib%2Fgists%2F%2Fother%2FNetworkDataCenterManagement1.adoc' do
        it { should eq 'https://raw.githubusercontent.com/neo4j-contrib/gists/master/other/NetworkDataCenterManagement1.adoc' }
      end

      # blobs
      let_context id: 'github-kbastani/gists//meta/TimeScaleEventMetaModel.adoc' do
        it { should eq 'https://raw.githubusercontent.com/kbastani/gists/master/meta/TimeScaleEventMetaModel.adoc' }
      end
    end

    describe 'Dropbox' do
      let_context id: 'dropboxs-vhtxfibv7ycstrv/BankFraudDetection.adoc.txt?dl=0' do
        it { should eq 'https://dl.dropboxusercontent.com/s/vhtxfibv7ycstrv/BankFraudDetection.adoc.txt?dl=0' }
      end
    end

    describe 'copy.com' do
      # Public files
      let_context id: 'copy-7MuhBZKFDsCIPNLp' do
        it { should eq 'https://copy.com/7MuhBZKFDsCIPNLp?download=1' }
      end

      # Direct files
      let_context id: 'copy-7MuhBZKFDsCIPNLp/analysis.txt' do
        it { should eq 'https://copy.com/7MuhBZKFDsCIPNLp/analysis.txt?download=1' }
      end
    end
  end
end
