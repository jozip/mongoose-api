expect = require 'expect.js'
express = require 'express'
http = require 'http'
mongoose = require 'mongoose'
mongooseApi = require '..'

describe 'Mongoose API', ->
	
	describe 'serving path', ->
	
		app = null
		server = null
		models = []
		resource = null
		
		randomId = ->
			
			Math.floor Math.random() * 0xDEADBEEF
			
		beforeEach (done) ->
			
			app = express()
			app.configure ->
				
				app.use(express.bodyParser())
				app.use(app.router)
			
			server = http.createServer app
			server.listen SOCKETPATH, done
			
			[resource] = models = [
				_id: randomId()
				name: 'Name1'
				description: 'Hiii'
			,
				_id: randomId()
				name: 'Name2'
				description: 'Hola'
			]
			
			Model =
				
				collection: name: 'tests'
				
				schema: paths: name: true, description: true
				
				find: (fn) -> fn null, models
				
				findById: (id, fields, fn) ->
					
					fn = fields unless fn?
					
					result = null
					for model in models
						
						if "#{model._id}" is id
							result = model
							break
					
					fn null, result
				
				findByIdAndRemove: (id, fn) ->
					
					result = null
					
					for model, i in models
						
						if "#{model._id}" is id
							models.splice i, 1
							result = model
							break
					
					fn null, result
				
				create: (object, fn) ->
					
					object._id = randomId()
					
					models.push object
					fn null, object
					
				remove: (fn) ->
					
					models = []
					fn null, models
			
			mongooseApi.serveModel app, Model
				
		afterEach (done) ->
			
			server.close done
			
		describe 'index', ->
			
			it 'should serve all resources on a GET request', (done) ->
				
				req = httpRequest path: '/tests', (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(JSON.parse body).to.eql models
					
					done()
					
				req.end()
			
			it 'should add a resource on a POST request', (done) ->
				
				options =
					headers: 'Content-Type': 'application/x-www-form-urlencoded'
					method: 'POST'
					path: '/tests'
				
				req = httpRequest options, (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 201
					expect(models.length).to.be 3
					expect(models[2]['name']).to.be 'Test'
					
					done()
				
				req.end 'name=Test'
				
			it 'should reject a PUT request (for now)', (done) ->
				
				req = httpRequest method: 'PUT', path: '/tests', (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 405
					
					done()
				
				req.end 'name=Test'
				
			it 'should delete all resources on a DELETE request', (done) ->
				
				req = httpRequest method: 'DELETE', path: '/tests', (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(models.length).to.be 0
					
					done()
				
				req.end 'name=Test'
				
		describe 'resource', ->
		
			it 'should retrieve a resource on a GET request', (done) ->
				
				req = httpRequest path: "/tests/#{resource._id}", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(JSON.parse body).to.eql resource
					
					done()
				
				req.end()
				
			it "should return 404 on a GET request if the resource doesn't exist", (done) ->
				
				req = httpRequest path: "/tests/#{resource._id + 1}", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 404
					
					done()
				
				req.end()
				
			it 'should reject a POST request', (done) ->
				
				req = httpRequest method: 'POST', path: "/tests/#{resource._id}", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 405
					
					done()
				
				req.end()
				
			it 'should update a resource on a PUT request', (done) ->
				
				options =
					headers: 'Content-Type': 'application/x-www-form-urlencoded'
					method: 'PUT'
					path: "/tests/#{resource._id}"
				
				resource.save = (fn) ->
					
					fn null, this
				
				expect(resource.name).to.be 'Name1'
				
				req = httpRequest options, (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(resource.name).to.be 'HI'
					
					done()
				
				req.end "name=HI"
				
			it "should return 404 on a PUT request if the resource doesn't exist", (done) ->
				
				options =
					headers: 'Content-Type': 'application/x-www-form-urlencoded'
					method: 'PUT'
					path: "/tests/#{resource._id + 1}"
				
				resource.save = (fn) ->
					
					fn null, this
				
				expect(resource.name).to.be 'Name1'
				
				req = httpRequest options, (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 404
					
					done()
				
				req.end "name=HI"
				
			it 'should delete a resource on a DELETE request', (done) ->
				
				req = httpRequest method: 'DELETE', path: "/tests/#{resource._id}", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(models.length).to.be 1
					
					done()
				
				req.end 'name=Test'
				
			it "should return 404 on a DELETE request if the resource doesn't exist", (done) ->
				
				req = httpRequest method: 'DELETE', path: "/tests/#{resource._id + 1}", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 404
					expect(models.length).to.be 2
					
					done()
				
				req.end 'name=Test'
				
		describe 'attributes', ->
				
			it 'should reject a POST request', (done) ->
				
				req = httpRequest method: 'POST', path: "/tests/#{resource._id}/name", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 405
					
					done()
				
				req.end()
				
			it 'should be able to retrieve a single resource attribute on a GET request', (done) ->
				
				req = httpRequest method: 'GET', path: "/tests/#{resource._id}/name", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(JSON.parse body).to.eql name: 'Name1'
					
					done()
				
				req.end()
				
			it 'should be able to retrieve multiple resource attributes on a GET request', (done) ->
				
				req = httpRequest method: 'GET', path: "/tests/#{resource._id}/name+description", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 200
					expect(JSON.parse body).to.eql name: 'Name1', description: 'Hiii'
					
					done()
				
				req.end()
				
			it "should return 404 on a GET request if the resource doesn't exist", (done) ->
				
				req = httpRequest method: 'GET', path: "/tests/#{resource._id + 1}/name", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 404
					
					done()
				
				req.end()
				
			it 'should reject a PUT request', (done) ->
				
				req = httpRequest method: 'PUT', path: "/tests/#{resource._id}/name", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 405
					
					done()
				
				req.end()
				
			it 'should reject a DELETE request', (done) ->
				
				req = httpRequest method: 'DELETE', path: "/tests/#{resource._id}/name", (error, res, body) ->
					
					throw error if error?
					
					expect(res.statusCode).to.be 405
					
					done()
				
				req.end()
				
	describe 'model discovery', ->
	
		TestModels = [
			
			TestModel = mongoose.model 'Test1', new mongoose.Schema
				name: String
				description: String
				
			mongoose.model 'Test2', new mongoose.Schema
				title: String
				createdAt: Date
		]
		
		app = {}
		modelsLoaded = 0
		serveModel = mongooseApi.serveModel
		
		beforeEach ->
			
			mongooseApi.serveModel = (app, Model) -> modelsLoaded += 1
			
		afterEach ->
			
			modelsLoaded = 0
			mongooseApi.serveModel = serveModel
		
		it 'should lookup and serve mongoose models automatically', ->
			
			mongooseApi.serveModels app
			expect(modelsLoaded).to.be 2
		
		it 'should be able to serve arbitrary models only', ->
			
			mongooseApi.serveModels app, [TestModel]
			expect(modelsLoaded).to.be 1
		
SOCKETPATH = "#{__dirname}/test.sock"

httpRequest = (options, fn) ->
	
	options.socketPath = SOCKETPATH
	options.method ?= 'GET'
	
	req = http.request options, (res) ->
		
		res.body = ''
		res.setEncoding 'utf8'
		res.on 'data', (chunk) -> res.body += chunk
		res.on 'end', ->
			
			fn null, res, res.body
	
	req.on 'error', (error) -> fn error, null, null
	
	req
