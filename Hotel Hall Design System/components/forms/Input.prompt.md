Text input for search, guest details and payment fields.

```jsx
<Input label="Email" placeholder="you@example.com" hint="Your confirmation goes here." />
<Input label="Card number" error="That card was declined." />
```

Focus is a teal ring. `Field` is exported separately to wrap any non-input control with the same label/hint/error treatment.
