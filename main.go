package main

import (
	"fmt"
	"net/http"
	"text/template"

	"github.com/gorilla/mux"
	"github.com/pkg/errors"
)

var templates *template.Template

func init() {
	templates = template.Must(template.ParseGlob("./templates/*.html")) //Initialize all the html templates in the templates folder
}

const maxUploadSize = 2 * 1024 * 1024
const uploadPath = "./tmp"

func main() {
	mux := mux.NewRouter()

	mux.HandleFunc("/", indexHandler)
	mux.HandleFunc("/upload", fileUploadHandler).Methods("POST")
	mux.HandleFunc("/delete/{file}", deleteHandler)

	mux.PathPrefix("/scripts/").Handler(http.StripPrefix("/scripts/", http.FileServer(http.Dir("./scripts"))))
	mux.PathPrefix("/download/").Handler(http.StripPrefix("/download/", http.FileServer(http.Dir("./upload"))))

	mux.HandleFunc("/getNewID", newIDHandler)
	mux.HandleFunc("/{id}/getTask", taskHandler)
	mux.HandleFunc("/ping", pingHandler)

	err := http.ListenAndServe("0.0.0.0:80", mux)
	if err != nil {
		panic(fmt.Sprintf("%+v", errors.WithStack(err)))
	}
}
