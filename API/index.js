const express = require('express');
const app = express();

app.use(express.json());

// GET - Welcome Route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to FoodExpress API' });
});

// GET - All Restaurants
app.get('/restaurants', (req, res) => {
    res.json([
        { id: 1, name: 'Pizza Palace', cuisine: 'Italian' },
        { id: 2, name: 'Burger Barn', cuisine: 'American' },
        { id: 3, name: 'Sushi World', cuisine: 'Japanese' }
    ]);
});

// GET - All Menu Items
app.get('/menu', (req, res) => {
    res.json([
        { id: 1, item: 'Margherita Pizza', price: 12.99 },
        { id: 2, item: 'Cheeseburger', price: 8.99 },
        { id: 3, item: 'California Roll', price: 10.99 }
    ]);
});

// GET - All Orders
app.get('/orders', (req, res) => {
    res.json([
        { id: 1, customer: 'John', item: 'Pizza', status: 'Delivered' },
        { id: 2, customer: 'Jane', item: 'Burger', status: 'Pending' }
    ]);
});
// new Post API
app.post('/delivery', (req, res) => {
    const { customer, address, item } = req.body;  
    if (!customer || !address || !item) {
        return res.status(400).json({ error: 'Missing required fields' });
    }      
    res.json({ message: 'Delivery request received', customer, address, item });
});
// new put API
app.put('/orders/:id', (req, res) => {
    const orderId = req.params.id;
    const { status } = req.body;    
    if (!status) {
        return res.status(400).json({ error: 'Missing status field' });
    }
    res.json({ message: `Order ${orderId} status updated to ${status}` });
});

// new delete API
app.delete('/orders/:id', (req, res) => {
    const orderId = req.params.id;    
    res.json({ message: `Order ${orderId} has been deleted` });
});


const PORT = 3000;
app.listen(PORT, () => {
    console.log(`FoodExpress API running on port ${PORT}`);
});