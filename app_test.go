package main

import (
	"net/http"
	"testing"
	"time"

	"github.com/appleboy/gofight"
	"github.com/buger/jsonparser"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func TestGinHelloWorld(t *testing.T) {
	gin.SetMode(gin.TestMode)
	r := gofight.New()

	r.GET("/").
		Run(GetMainEngine(), func(r gofight.HTTPResponse, rq gofight.HTTPRequest) {
			data := []byte(r.Body.String())

			value, _ := jsonparser.GetString(data, "text")

			assert.Equal(t, "The truth is out there.", value)
			assert.Equal(t, http.StatusOK, r.Code)
		})
}

func TestRunNormalServer(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()

	go func() {
		main()
	}()
	// have to wait for the goroutine to start and run the server
	// otherwise the main thread will complete
	time.Sleep(5 * time.Millisecond)

	assert.Error(t, router.Run(":8000"))
	gofight.TestRequest(t, "http://localhost:8000/")
}
