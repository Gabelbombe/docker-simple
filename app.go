package main

import (
    "fmt"
    "net/http"
    "strings"
    "log"
)

func sayAppName(w http.ResponseWriter, r *http.Request) {
    r.ParseForm()  // parse arguments, you have to call this by yourself
    fmt.Println(r.Form)  // print form information in server side
    fmt.Println("path", r.URL.Path)
    fmt.Println("scheme", r.URL.Scheme)
    fmt.Println(r.Form["url_long"])
    for k, v := range r.Form {
        fmt.Println("key:", k)
        fmt.Println("val:", strings.Join(v, ""))
    }
    fmt.Fprintf(w, "The truth is out there.") // send data to client side
}

func main() {
    http.HandleFunc("/", sayAppName) // set router
    err := http.ListenAndServe(":9090", nil) // set listen port
    if err != nil {
        log.Fatal("ListenAndServe: ", err)
    }
}
