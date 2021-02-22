package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"time"
)

var turtles []int

func newIDHandler(w http.ResponseWriter, r *http.Request) {
	randSource := rand.NewSource(time.Now().UnixNano())

	rand := rand.New(randSource)

	id := rand.Intn(1000000)

	turtles = append(turtles, id)

	json.NewEncoder(w).Encode(struct{ ID int }{id})
}

func taskHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(struct{ Tasks []string }{[]string{"test.lua false ---v2.0.1"}})
	fmt.Println("test")
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(struct{ Pong string }{"pong"})
	fmt.Println("-------test")
}
