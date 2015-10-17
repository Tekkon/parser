require 'open-uri'
require 'nokogiri'
require 'json'
require 'aws-sdk'

module Parser
	KEY_ID = 'AKIAJUDK62CALEATMZMQ'
	SECRET_KEY = '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'
	REGION = 'us-west-2'
	SERVER = "s3-us-west-2.amazonaws.com"
	FOLDER = "img"	

	def self.parse url, bucket
		puts 'Opening URL...'
		html = open(url)
		doc = Nokogiri::HTML(html)

		puts 'Parsing images...'

		Nokogiri::HTML(open(url)).xpath("//img/@src").each do |src|
		  uri = URI.join(url, src).to_s.split('?')[0]
		  #images.push({ localUri: uri, awsUri: get_aws_uri(File.basename(uri)) })
		  begin
		  	File.open(FOLDER + '/' + File.basename(uri),'wb'){ |f| f.write(open(uri).read) }
		  rescue
		  	puts "Can't get image from url #{uri}"
		  end
		end

		puts 'Connecting to Amazon CloudFront...'
		Aws.config.update({
		  region: REGION,
		  credentials: Aws::Credentials.new(KEY_ID, SECRET_KEY),
		  ssl_verify_peer: false
		})

		puts 'Uploading files...'
		images = []
		s3 = Aws::S3::Resource.new(region: REGION)
		Dir.glob(FOLDER + "/*").each do |file|
		 	unless File.directory?(file)
				obj = s3.bucket(bucket).object(File.basename(file))
				obj.upload_file(file, :acl => "public-read")
				images.push(uri: obj.public_url)
			end
		end

		JSON.pretty_generate(images)
	end
end

puts Parser::parse 'http://www.utkonos.ru/item/41/1011055', 'utkonos'