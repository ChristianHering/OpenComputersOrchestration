package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

func fileUploadHandler(w http.ResponseWriter, r *http.Request) {
	r.ParseMultipartForm(10 << 20)

	file, handler, err := r.FormFile("myFile")
	if err != nil {
		fmt.Println("Error Retrieving the File")
		fmt.Println(err)
		return
	}
	defer file.Close()

	f, err := os.OpenFile("./upload/"+handler.Filename, os.O_RDWR|os.O_CREATE, 0777)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	fb, err := ioutil.ReadAll(file)
	if err != nil {
		fmt.Println(err)
	}

	f.Write(fb)

	http.Redirect(w, r, "./..", http.StatusSeeOther)
}
