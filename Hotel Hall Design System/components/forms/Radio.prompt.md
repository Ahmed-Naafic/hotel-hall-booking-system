Mutually exclusive choices — rate plans, bed configuration, payment timing.

```jsx
<RadioGroup label="Rate" value={rate} onChange={setRate} options={[
  {value:'flex',label:'Flexible',description:'Free cancellation until Aug 12'},
  {value:'saver',label:'Advance saver',description:'Non-refundable · save $32'},
]} />
```
