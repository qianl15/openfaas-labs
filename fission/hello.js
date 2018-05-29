module.exports = async function(context) {
    let amount = 0;
    for (let j = 0; j < 5000; j++) {
        for (let i = 0; i < 10000; i++) {
            amount += i * i;
        }
    }
    return {
        status: 200,
        body: "Hello, World! Amount:" + amount.toString() + "\n"
    };
}
