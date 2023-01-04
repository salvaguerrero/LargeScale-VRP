// selecting dom element
const textInput = document.querySelector("#inputPart");
const textOutput = document.querySelector("#showOutput");
const btn = document.querySelector("#submitInput");

// adding event listener to button
btn.addEventListener("click", fetchHandler);

// selecting loading div
const loader = document.querySelector("#loading");

// showing loading
function displayLoading() {
    loader.classList.add("display");
}

// hiding loading 
function hideLoading() {
    loader.classList.remove("display");
}


var url = "http://127.0.0.1:8000/api/model/execute/1" 

function fetchHandler(event) {
    displayLoading()
    
    var finalURL = url;

    fetch(finalURL)
        .then(response => response.json())
        .then(json => {
            hideLoading()
            location.reload(true)
        })
}

