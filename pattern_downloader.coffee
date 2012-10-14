do () ->
	request 			= require 'request'
	path 				= require 'path'
	fs 					= require 'fs'
	cheerio 			= require 'cheerio'
	baseURL 			= 'http://subtlepatterns.com/'
	patternsFolder 		= "#{__dirname}/patterns"
	downloaded 			= 0
	notDownloaded 		= 0
	totalFiles 			= 0
	currentPage 		= 1

	# copy from https://gist.github.com/1715822
	rmdirRecursiveSync = (path) ->
		files
		file
		fileStats
		filesLength

		if path[path.length - 1] isnt '/' then path = path + '/'

		files = fs.readdirSync(path)
		filesLength = files.length

		if filesLength?
			for file in files
				fileStats = fs.statSync(path + file);
				if fileStats.isFile() then fs.unlinkSync(path + file)
				if fileStats.isDirectory() then rmdirRecursiveSync(path + file)
		
		fs.rmdirSync(path);

	# if  folder exists remove it and create again
	(initializeFolder = () ->
		rmdirRecursiveSync patternsFolder if fs.existsSync patternsFolder
		fs.mkdirSync patternsFolder)()

	# get html for page num = x
	(getPage = (page = 1) ->
		currentPage = page
		url = baseURL
		url += "page/#{page}" unless page is 1

		request.get(url, ( err, resp, body ) -> 
			if not err 
				if resp.statusCode is 200

					# grab page pattern links to download
					links = getPatternsLinks body
					
					# add to total files
					totalFiles += links.length

					# download files, index start with zero
					downloadFile links

				else if resp.statusCode is 404 # when 404 is returned, we know that there's no pages
					console.log ''
					console.log '======================================================================='
					console.log "Successfuly downloaded #{downloaded} of #{totalFiles}"
					console.log "Not downloaded #{notDownloaded} of #{totalFiles}"
					console.log '======================================================================='
			else
				console.log 'Aborting because', err
		))()

	# get all links with class download and having href
	# a.download actually have the link to download the pattern
	getPatternsLinks = ( body ) ->
		links = []
		$ = cheerio.load body

		(value.attribs.href for value in $('a.download[href]'))

	# download file 'sync', only download the next when finish the current
	downloadFile = ( files, i = 0 ) ->
		file = files[ i ];
		filename = path.basename file

		request( 
			file,
			( err, resp, body ) -> 
				if not err and resp.statusCode is 200
					if resp.statusCode is 200 
						console.log "The file #{filename} was successfuly download"
						downloaded++
				else
					msg = "The request for file #{filename} has ended with ";

					if not err then msg += "error #{error}"
					else msg += "http status code #{resp.statusCode}"

					notDownload++

				if ++i < files.length then downloadFile files, i
				else getPage currentPage + 1

			).pipe( fs.createWriteStream("#{patternsFolder}/#{filename}") )