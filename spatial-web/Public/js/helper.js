document.addEventListener('DOMContentLoaded', (event) => {
    // Retrieve selections from local storage
    const location = localStorage.getItem('location');
    const distance = localStorage.getItem('distance');
    const unit = localStorage.getItem('unit');

    if (location) {
        document.getElementById('location').value = location;
    }
    if (distance) {
        document.getElementById('distance').value = distance;
    }
    if (unit) {
        document.getElementById('unit').value = unit;
    }
});

function saveSelections() {
    // Save selections to local storage
    const location = document.getElementById('location').value;
    const distance = document.getElementById('distance').value;
    const unit = document.getElementById('unit').value;

    localStorage.setItem('location', location);
    localStorage.setItem('distance', distance);
    localStorage.setItem('unit', unit);
}