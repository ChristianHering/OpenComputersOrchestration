package main

import (
	"io/ioutil"
	"net/http"
	"os"

	"github.com/gorilla/mux"
)

func indexHandler(w http.ResponseWriter, r *http.Request) {
	c, err := ioutil.ReadDir("./upload")
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	var files []string

	for i := 0; i < len(c); i++ {
		item := c[i]
		if !item.IsDir() {
			files = append(files, item.Name())
		}
	}

	err = templates.ExecuteTemplate(w, "index.html", files)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
}

func deleteHandler(w http.ResponseWriter, r *http.Request) {
	err := os.Remove("./upload/" + mux.Vars(r)["file"])
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	http.Redirect(w, r, "./..", http.StatusSeeOther)
}

func uploadHandler(w http.ResponseWriter, r *http.Request) {
	err := templates.ExecuteTemplate(w, "upload.html", nil)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
}
